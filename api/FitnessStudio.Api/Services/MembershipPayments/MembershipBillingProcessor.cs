using FitnessStudio.Api.Data;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MembershipPayments;

public class MembershipBillingProcessor : IMembershipBillingProcessor
{
    private readonly FitnessStudioDbContext _db;
    private readonly IPaymentSettingsService _settingsService;
    public MembershipBillingProcessor(FitnessStudioDbContext db, IPaymentSettingsService settingsService) { _db = db; _settingsService = settingsService; }

    public async Task ProcessAsync(CancellationToken cancellationToken = default)
    {
        var studios = await _db.Studios.AsNoTracking().Where(x => x.Status == "active").Select(x => new { x.Id, x.Timezone }).ToListAsync(cancellationToken);
        foreach (var studio in studios)
        {
            var timezone = TimeZoneInfo.FindSystemTimeZoneById(studio.Timezone);
            var localNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone);
            var today = DateOnly.FromDateTime(localNow);
            var settings = await _settingsService.GetAsync(studio.Id);
            if (!settings.IsComplete) continue;
            var memberships = await _db.MemberMemberships.Include(x => x.MembershipPlan)
                .Where(x => x.StudioId == studio.Id && x.NextBillingOn.HasValue && x.NextBillingOn.Value <= today)
                .ToListAsync(cancellationToken);
            foreach (var membership in memberships)
            {
                await MembershipObligationGenerator.GenerateDueAsync(
                    _db, membership, settings, today, cancellationToken);
            }
            await _db.SaveChangesAsync(cancellationToken);
            await CreateNotificationsAsync(studio.Id, today, localNow.TimeOfDay, settings, cancellationToken);
        }
    }

    private async Task CreateNotificationsAsync(long studioId, DateOnly today, TimeSpan localTime, Dtos.Payments.PaymentSettingsResponse settings, CancellationToken ct)
    {
        if (localTime < settings.NotificationTime.ToTimeSpan()) return;
        var obligations = await _db.MembershipPaymentObligations.Include(x => x.MemberMembership).ThenInclude(x => x.Member).ThenInclude(x => x.AppUserStudio).ThenInclude(x => x!.AppUser)
            .Where(x => x.StudioId == studioId && x.Status != "paid" && x.DueOn <= today).ToListAsync(ct);
        var admins = await _db.AppUserRoles.Where(x => x.Role == "admin" && x.AppUserStudio.StudioId == studioId && x.AppUserStudio.Status == "active").Select(x => x.AppUserStudio.AppUserId).ToListAsync(ct);
        foreach (var payment in obligations)
        {
            var offset = today.DayNumber - payment.DueOn.DayNumber;
            if (payment.Status == "pending" && settings.MemberReminderDays.Contains(offset) && payment.MemberMembership.Member.AppUserStudio is { } membership)
                AddNotification(membership.AppUserId, payment, "member_payment_reminder", offset, "Članarina čeka uplatu", $"Iznos {payment.AmountDue:0.00} EUR dospio je {payment.DueOn:dd.MM.yyyy}.");
            if (settings.AdminReminderDays.Contains(offset))
                foreach (var adminId in admins) AddNotification(adminId, payment, "admin_payment_reminder", offset, "Nepotvrđena članarina", $"{payment.MemberMembership.Member.FirstName} {payment.MemberMembership.Member.LastName}: {payment.AmountDue:0.00} EUR.");
        }
        await _db.SaveChangesAsync(ct);
    }

    private void AddNotification(long userId, MembershipPaymentObligation payment, string type, int offset, string title, string body)
    {
        if (_db.AppNotifications.Local.Any(x => x.AppUserId == userId && x.PaymentObligationId == payment.Id && x.NotificationType == type && x.DayOffset == offset)
            || _db.AppNotifications.Any(x => x.AppUserId == userId && x.PaymentObligationId == payment.Id && x.NotificationType == type && x.DayOffset == offset)) return;
        _db.AppNotifications.Add(new AppNotification { StudioId = payment.StudioId, AppUserId = userId, PaymentObligationId = payment.Id, NotificationType = type, DayOffset = offset, Title = title, Body = body, CreatedAt = DateTime.UtcNow });
    }
}
