using System.Globalization;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MembershipPayments;

public class MembershipPaymentsService : IMembershipPaymentsService
{
    private readonly FitnessStudioDbContext _db;
    private readonly ICurrentUserContext _currentUser;
    public MembershipPaymentsService(FitnessStudioDbContext db, ICurrentUserContext currentUser) { _db = db; _currentUser = currentUser; }

    public async Task<List<MembershipPaymentResponse>> GetMineAsync()
    {
        if (!_currentUser.MemberId.HasValue) return [];
        var today = await StudioTodayAsync();
        var query = Query()
            .Where(x => x.MemberMembership.MemberId == _currentUser.MemberId)
            .OrderByDescending(x => x.PeriodStartsOn);
        return await Project(query, today).ToListAsync();
    }

    public async Task<List<MembershipPaymentResponse>> GetAllAsync(string? view, long? memberId)
    {
        var today = await StudioTodayAsync();
        var query = Query();
        query = (view ?? "all").Trim().ToLowerInvariant() switch
        {
            "pending" => query.Where(x => x.Status == "pending" && x.DueOn >= today),
            "reported" => query.Where(x => x.Status == "reported"),
            "overdue" => query.Where(x => x.Status == "pending" && x.DueOn < today),
            "paid" => query.Where(x => x.Status == "paid"),
            _ => query
        };
        if (memberId.HasValue) query = query.Where(x => x.MemberMembership.MemberId == memberId);
        return await Project(query.OrderByDescending(x => x.DueOn), today).ToListAsync();
    }

    public async Task<ServiceResult<MembershipPaymentResponse>> GetAsync(long id)
    {
        var today = await StudioTodayAsync();
        var item = await Project(AuthorizedQuery().Where(x => x.Id == id), today).FirstOrDefaultAsync();
        return item is null ? ServiceResult<MembershipPaymentResponse>.NotFound("Payment not found.", "The payment obligation does not exist.") : ServiceResult<MembershipPaymentResponse>.Success(item);
    }

    public async Task<MembershipPaymentSummaryResponse> GetSummaryAsync()
    {
        var today = await StudioTodayAsync();
        var query = Query();
        return new(
            await query.CountAsync(x => x.Status == "pending" && x.DueOn >= today),
            await query.CountAsync(x => x.Status == "reported"),
            await query.CountAsync(x => x.Status == "pending" && x.DueOn < today),
            await query.CountAsync(x => x.Status == "paid"));
    }

    public async Task<ServiceResult> ReportAsync(long id)
    {
        if (!_currentUser.MemberId.HasValue) return ServiceResult.Forbidden("Member access required.", "Only a member can report their payment.");
        var item = await Query().FirstOrDefaultAsync(x => x.Id == id && x.MemberMembership.MemberId == _currentUser.MemberId);
        if (item is null) return ServiceResult.NotFound("Payment not found.", "The payment obligation does not exist.");
        if (item.Status != "pending") return ServiceResult.Conflict("Payment cannot be reported.", "Only a pending payment can be reported.");
        item.Status = "reported"; item.ReportedAt = DateTime.UtcNow; item.ReportedByUserId = _currentUser.UserId; item.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(); return ServiceResult.Success();
    }

    public Task<ServiceResult> ConfirmAsync(long id) => ChangeByAdminAsync(id, "confirm");
    public Task<ServiceResult> RejectReportAsync(long id) => ChangeByAdminAsync(id, "reject");
    public Task<ServiceResult> ReopenAsync(long id) => ChangeByAdminAsync(id, "reopen");

    public async Task<ServiceResult<string>> GetHub3PayloadAsync(long id)
    {
        var item = await AuthorizedQuery().Include(x => x.MemberMembership).ThenInclude(x => x.Member).FirstOrDefaultAsync(x => x.Id == id);
        if (item is null) return ServiceResult<string>.NotFound("Payment not found.", "The payment obligation does not exist.");
        var amount = ((long)Math.Round(item.AmountDue * 100, MidpointRounding.AwayFromZero)).ToString("D15", CultureInfo.InvariantCulture);
        var payer = Crop($"{item.MemberMembership.Member.FirstName} {item.MemberMembership.Member.LastName}", 30);
        var fields = new[] { "HRVHUB30", "EUR", amount, payer, "", "", Crop(item.RecipientName, 25), "", "", item.Iban, item.PaymentModel, item.PaymentReference, "", Crop(item.PaymentDescription, 35) };
        return ServiceResult<string>.Success(string.Join('\n', fields) + "\n");
    }

    private async Task<ServiceResult> ChangeByAdminAsync(long id, string action)
    {
        if (!_currentUser.IsInRole(AuthRoles.Admin)) return ServiceResult.Forbidden("Admin access required.", "Only an admin can change payment status.");
        var item = await Query().Include(x => x.MemberMembership).FirstOrDefaultAsync(x => x.Id == id);
        if (item is null) return ServiceResult.NotFound("Payment not found.", "The payment obligation does not exist.");
        var now = DateTime.UtcNow;
        if (action == "confirm" && item.Status is "pending" or "reported") { item.Status = "paid"; item.ConfirmedAt = now; item.ConfirmedByUserId = _currentUser.UserId; }
        else if (action == "reject" && item.Status == "reported") { item.Status = "pending"; item.ReportedAt = null; item.ReportedByUserId = null; Recalculate(item); }
        else if (action == "reopen" && item.Status == "paid") { item.Status = "pending"; item.ConfirmedAt = null; item.ConfirmedByUserId = null; Recalculate(item); }
        else return ServiceResult.Conflict("Invalid payment transition.", $"The payment cannot be changed using action '{action}'.");
        item.UpdatedAt = now; await _db.SaveChangesAsync(); return ServiceResult.Success();
    }

    private static void Recalculate(MembershipPaymentObligation item)
    {
        if (item.MemberMembership.EndsOn is { } end && end < item.PeriodEndsOn)
            item.AmountDue = MembershipCycle.Prorate(item.FullAmount, item.PeriodStartsOn, item.PeriodEndsOn, end);
    }

    private IQueryable<MembershipPaymentObligation> Query() => _db.MembershipPaymentObligations.Where(x => x.StudioId == _currentUser.StudioId);
    private IQueryable<MembershipPaymentObligation> AuthorizedQuery() => _currentUser.IsInRole(AuthRoles.Admin) ? Query() : Query().Where(x => _currentUser.MemberId.HasValue && x.MemberMembership.MemberId == _currentUser.MemberId.Value);
    private static IQueryable<MembershipPaymentResponse> Project(IQueryable<MembershipPaymentObligation> query, DateOnly today) => query.Select(x => new MembershipPaymentResponse(
        x.Id, x.MemberMembershipId, x.MemberMembership.MemberId, x.MemberMembership.Member.FirstName + " " + x.MemberMembership.Member.LastName, x.PlanName,
        x.PeriodStartsOn, x.PeriodEndsOn, x.DueOn, x.FullAmount, x.AmountDue, x.Currency, x.Status, x.DueOn < today && x.Status != "paid",
        x.RecipientName, x.Iban, x.PaymentModel, x.PaymentReference, x.PaymentDescription, x.ReportedAt, x.ConfirmedAt, $"/api/membership-payments/{x.Id}/barcode"));
    private async Task<DateOnly> StudioTodayAsync() { var tz = await _db.Studios.Where(x => x.Id == _currentUser.StudioId).Select(x => x.Timezone).SingleAsync(); return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById(tz))); }
    private static string Crop(string value, int max) => value.Length <= max ? value : value[..max];
}
