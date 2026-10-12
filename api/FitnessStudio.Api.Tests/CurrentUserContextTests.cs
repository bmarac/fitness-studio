using System.Security.Claims;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Services.Auth;
using Microsoft.AspNetCore.Http;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class CurrentUserContextTests
{
    [Fact]
    public void ClaimsExposeAuthenticatedUserIdentity()
    {
        var context = CreateContext(
            new Claim(ClaimTypes.NameIdentifier, "42"),
            new Claim(ClaimTypes.Email, "member@example.com"),
            new Claim(AuthClaimTypes.StudioId, "7"),
            new Claim(AuthClaimTypes.MemberId, "11"),
            new Claim(AuthClaimTypes.TrainerId, "13"));

        Assert.Equal(42, context.UserId);
        Assert.Equal("member@example.com", context.Email);
        Assert.Equal(7, context.StudioId);
        Assert.Equal(11, context.MemberId);
        Assert.Equal(13, context.TrainerId);
    }

    [Fact]
    public void RolesAreCaseInsensitiveAndMemberOnlyRecognizesMember()
    {
        var context = CreateContext(new Claim(ClaimTypes.Role, "MEMBER"));

        Assert.Contains(AuthRoles.Member, context.Roles);
        Assert.True(context.IsInRole("MeMbEr"));
        Assert.True(context.IsMemberOnly);
    }

    [Theory]
    [InlineData(AuthRoles.Admin)]
    [InlineData(AuthRoles.Trainer)]
    public void MemberWithStaffRoleIsNotMemberOnly(string staffRole)
    {
        var context = CreateContext(
            new Claim(ClaimTypes.Role, AuthRoles.Member),
            new Claim(ClaimTypes.Role, staffRole));

        Assert.False(context.IsMemberOnly);
    }

    [Fact]
    public void MissingOrBlankOptionalClaimsReturnNull()
    {
        var context = CreateContext(new Claim(AuthClaimTypes.MemberId, " "));

        Assert.Null(context.MemberId);
        Assert.Null(context.TrainerId);
    }

    [Fact]
    public void MissingHttpContextHasNoRoles()
    {
        var context = new CurrentUserContext(new HttpContextAccessor());

        Assert.Empty(context.Roles);
        Assert.False(context.IsMemberOnly);
    }

    [Theory]
    [InlineData(ClaimTypes.NameIdentifier)]
    [InlineData(ClaimTypes.Email)]
    [InlineData(AuthClaimTypes.StudioId)]
    public void MissingRequiredClaimThrows(string claimType)
    {
        var context = CreateContext();

        var exception = Assert.Throws<InvalidOperationException>(() => ReadRequiredClaim(context, claimType));

        Assert.Contains($"missing the '{claimType}' claim", exception.Message);
    }

    [Theory]
    [InlineData(ClaimTypes.NameIdentifier)]
    [InlineData(AuthClaimTypes.StudioId)]
    public void InvalidRequiredNumericClaimThrows(string claimType)
    {
        var context = CreateContext(new Claim(claimType, "not-a-number"));

        var exception = Assert.Throws<InvalidOperationException>(() => ReadRequiredClaim(context, claimType));

        Assert.Contains($"invalid '{claimType}' claim", exception.Message);
    }

    [Theory]
    [InlineData(AuthClaimTypes.MemberId)]
    [InlineData(AuthClaimTypes.TrainerId)]
    public void InvalidOptionalNumericClaimThrows(string claimType)
    {
        var context = CreateContext(new Claim(claimType, "not-a-number"));

        var exception = Assert.Throws<InvalidOperationException>(() => ReadOptionalClaim(context, claimType));

        Assert.Contains($"invalid '{claimType}' claim", exception.Message);
    }

    private static CurrentUserContext CreateContext(params Claim[] claims)
    {
        var httpContext = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(claims, "test"))
        };

        return new CurrentUserContext(new HttpContextAccessor { HttpContext = httpContext });
    }

    private static object ReadRequiredClaim(CurrentUserContext context, string claimType)
    {
        return claimType switch
        {
            ClaimTypes.NameIdentifier => context.UserId,
            ClaimTypes.Email => context.Email,
            AuthClaimTypes.StudioId => context.StudioId,
            _ => throw new ArgumentOutOfRangeException(nameof(claimType))
        };
    }

    private static long? ReadOptionalClaim(CurrentUserContext context, string claimType)
    {
        return claimType switch
        {
            AuthClaimTypes.MemberId => context.MemberId,
            AuthClaimTypes.TrainerId => context.TrainerId,
            _ => throw new ArgumentOutOfRangeException(nameof(claimType))
        };
    }
}
