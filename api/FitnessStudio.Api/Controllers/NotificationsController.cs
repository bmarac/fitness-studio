using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.Notifications;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Controllers;

[ApiController, Authorize, Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly FitnessStudioDbContext _db;
    private readonly ICurrentUserContext _currentUser;
    public NotificationsController(FitnessStudioDbContext db, ICurrentUserContext currentUser) { _db = db; _currentUser = currentUser; }

    [HttpGet]
    public async Task<ActionResult<List<AppNotificationResponse>>> Get() => Ok(await _db.AppNotifications.AsNoTracking()
        .Where(x => x.AppUserId == _currentUser.UserId).OrderByDescending(x => x.CreatedAt)
        .Select(x => new AppNotificationResponse(x.Id, x.PaymentObligationId, x.NotificationType, x.Title, x.Body, x.ReadAt, x.CreatedAt)).Take(100).ToListAsync());

    [HttpPost("{id:long}/read")]
    public async Task<IActionResult> Read(long id)
    {
        var item = await _db.AppNotifications.FirstOrDefaultAsync(x => x.Id == id && x.AppUserId == _currentUser.UserId);
        if (item is null) return NotFound();
        item.ReadAt ??= DateTime.UtcNow; await _db.SaveChangesAsync(); return NoContent();
    }

    [HttpPut("device-token")]
    public async Task<IActionResult> Register(RegisterDeviceTokenRequest request)
    {
        var token = await _db.AppUserDeviceTokens.FirstOrDefaultAsync(x => x.Token == request.Token);
        if (token is null) { token = new AppUserDeviceToken { Token = request.Token, CreatedAt = DateTime.UtcNow }; _db.AppUserDeviceTokens.Add(token); }
        token.AppUserId = _currentUser.UserId; token.Platform = request.Platform; token.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(); return NoContent();
    }
}
