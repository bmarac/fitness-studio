using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberMemberships;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Validation;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembersAndMembershipsControllerTests
{
    [Fact]
    public async Task MembersControllerMapsSuccessfulActionsAndForwardsArguments()
    {
        var member = Member();
        var service = new FakeMembersService
        {
            ListResult = [member],
            GetResult = ServiceResult<MemberResponse>.Success(member),
            UpdateResult = ServiceResult.Success(),
            DeleteResult = ServiceResult.Success()
        };
        var controller = new MembersController(service);
        var request = new UpdateMemberRequest();

        Assert.Same(service.ListResult, Assert.IsType<OkObjectResult>(
            (await controller.GetMembers()).Result).Value);
        Assert.Same(member, Assert.IsType<OkObjectResult>(
            (await controller.GetMember(7)).Result).Value);
        Assert.IsType<NoContentResult>(await controller.UpdateMember(8, request));
        Assert.IsType<NoContentResult>(await controller.DeleteMember(9));
        Assert.Equal([7, 8, 9], service.Ids);
        Assert.Same(request, service.UpdateRequest);
    }

    [Fact]
    public async Task MembersControllerMapsFailureStatuses()
    {
        var service = new FakeMembersService
        {
            GetResult = ServiceResult<MemberResponse>.NotFound("Missing.", "Member not found."),
            UpdateResult = ServiceResult.Conflict("Duplicate.", "Email already exists."),
            DeleteResult = ServiceResult.Forbidden("Denied.", "Member cannot be deleted.")
        };
        var controller = new MembersController(service);

        SchedulingControllerTestAssertions.Problem((await controller.GetMember(1)).Result, 404);
        SchedulingControllerTestAssertions.Problem(
            await controller.UpdateMember(2, new UpdateMemberRequest()), 409);
        SchedulingControllerTestAssertions.Problem(await controller.DeleteMember(3), 403);
    }

    [Fact]
    public void MembersAuthorizationRequiresStaffForReadsAndAdminForWrites()
    {
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(typeof(MembersController));
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(MembersController), nameof(MembersController.GetMembers), AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(MembersController), nameof(MembersController.GetMember), AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(MembersController), nameof(MembersController.UpdateMember), AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(MembersController), nameof(MembersController.DeleteMember), AuthRoles.Admin);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("active")]
    [InlineData("INACTIVE")]
    [InlineData("paused")]
    [InlineData("BLOCKED")]
    public void MemberStatusValidatorAcceptsSupportedValues(string? value)
    {
        var result = new AllowedMemberStatusAttribute().GetValidationResult(
            value, new ValidationContext(new object()));

        Assert.Equal(ValidationResult.Success, result);
    }

    [Fact]
    public void MemberStatusValidatorRejectsUnknownValueWithAllowedList()
    {
        var result = new AllowedMemberStatusAttribute().GetValidationResult(
            "deleted", new ValidationContext(new object()));

        Assert.Contains("active", result!.ErrorMessage);
        Assert.Contains("inactive", result.ErrorMessage);
        Assert.Contains("paused", result.ErrorMessage);
        Assert.Contains("blocked", result.ErrorMessage);
    }

    [Fact]
    public async Task MembershipControllerMapsSuccessfulLifecycleAndForwardsArguments()
    {
        var membership = Membership();
        var billing = new SetMembershipBillingResponse(membership, 2, new DateOnly(2026, 12, 1));
        var service = new FakeMemberMembershipsService
        {
            ListResult = [membership],
            GetResult = ServiceResult<MemberMembershipResponse>.Success(membership),
            CreateResult = ServiceResult<MemberMembershipResponse>.Success(membership),
            UpdateResult = ServiceResult.Success(),
            DeleteResult = ServiceResult.Success(),
            BillingResult = ServiceResult<SetMembershipBillingResponse>.Success(billing),
            EndResult = ServiceResult.Success()
        };
        var controller = new MemberMembershipsController(service);
        var create = new CreateMemberMembershipRequest();
        var update = new UpdateMemberMembershipRequest();
        var setBilling = new SetMembershipBillingRequest();
        var end = new EndMembershipRequest();

        Assert.Same(service.ListResult, Assert.IsType<OkObjectResult>(
            (await controller.GetMemberships()).Result).Value);
        Assert.Same(membership, Assert.IsType<OkObjectResult>(
            (await controller.GetMembership(10)).Result).Value);
        var created = Assert.IsType<CreatedAtActionResult>(
            (await controller.CreateMembership(create)).Result);
        Assert.Equal(nameof(MemberMembershipsController.GetMembership), created.ActionName);
        Assert.Equal(31L, created.RouteValues!["id"]);
        Assert.Same(membership, created.Value);
        Assert.IsType<NoContentResult>(await controller.UpdateMembership(11, update));
        Assert.IsType<NoContentResult>(await controller.DeleteMembership(12));
        Assert.Same(billing, Assert.IsType<OkObjectResult>(
            (await controller.SetBilling(13, setBilling)).Result).Value);
        Assert.IsType<NoContentResult>(await controller.EndMembership(14, end));
        Assert.Equal([10, 11, 12, 13, 14], service.Ids);
        Assert.Same(create, service.CreateRequest);
        Assert.Same(update, service.UpdateRequest);
        Assert.Same(setBilling, service.BillingRequest);
        Assert.Same(end, service.EndRequest);
    }

    [Fact]
    public async Task MembershipControllerMapsLifecycleFailures()
    {
        var service = new FakeMemberMembershipsService
        {
            GetResult = ServiceResult<MemberMembershipResponse>.NotFound("Missing.", "Missing."),
            CreateResult = ServiceResult<MemberMembershipResponse>.Conflict("Conflict.", "Overlap."),
            UpdateResult = ServiceResult.NotFound("Missing.", "Missing."),
            DeleteResult = ServiceResult.Conflict("Conflict.", "Payments exist."),
            BillingResult = ServiceResult<SetMembershipBillingResponse>.Conflict(
                "Conflict.", "Billing is already enabled."),
            EndResult = ServiceResult.Forbidden("Denied.", "Wrong member.")
        };
        var controller = new MemberMembershipsController(service);

        SchedulingControllerTestAssertions.Problem((await controller.GetMembership(1)).Result, 404);
        SchedulingControllerTestAssertions.Problem(
            (await controller.CreateMembership(new CreateMemberMembershipRequest())).Result, 409);
        SchedulingControllerTestAssertions.Problem(
            await controller.UpdateMembership(2, new UpdateMemberMembershipRequest()), 404);
        SchedulingControllerTestAssertions.Problem(await controller.DeleteMembership(3), 409);
        SchedulingControllerTestAssertions.Problem(
            (await controller.SetBilling(4, new SetMembershipBillingRequest())).Result, 409);
        SchedulingControllerTestAssertions.Problem(
            await controller.EndMembership(5, new EndMembershipRequest()), 403);
    }

    [Fact]
    public void MembershipAuthorizationKeepsReadsAndSelfEndAuthenticatedOnly()
    {
        var type = typeof(MemberMembershipsController);
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(type);
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type, nameof(MemberMembershipsController.GetMemberships));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type, nameof(MemberMembershipsController.GetMembership));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type, nameof(MemberMembershipsController.EndMembership));
        foreach (var method in new[]
        {
            nameof(MemberMembershipsController.CreateMembership),
            nameof(MemberMembershipsController.UpdateMembership),
            nameof(MemberMembershipsController.DeleteMembership),
            nameof(MemberMembershipsController.SetBilling)
        })
        {
            SchedulingControllerTestAssertions.MethodRequiresRole(type, method, AuthRoles.Admin);
        }
    }

    private static MemberResponse Member() => new()
    {
        Id = 7,
        FirstName = "Ana",
        LastName = "Horvat",
        Email = "ana@example.com",
        Status = "active"
    };

    private static MemberMembershipResponse Membership() => new(
        31,
        7,
        "Ana Horvat",
        4,
        "Mjesečni",
        new DateOnly(2026, 10, 1),
        null,
        null,
        null,
        true);

    private sealed class FakeMembersService : IMembersService
    {
        public List<MemberResponse> ListResult { get; init; } = [];
        public ServiceResult<MemberResponse> GetResult { get; init; } = null!;
        public ServiceResult UpdateResult { get; init; } = null!;
        public ServiceResult DeleteResult { get; init; } = null!;
        public List<long> Ids { get; } = [];
        public UpdateMemberRequest? UpdateRequest { get; private set; }

        public Task<List<MemberResponse>> GetMembersAsync() => Task.FromResult(ListResult);

        public Task<ServiceResult<MemberResponse>> GetMemberAsync(long id)
        {
            Ids.Add(id);
            return Task.FromResult(GetResult);
        }

        public Task<ServiceResult> UpdateMemberAsync(long id, UpdateMemberRequest request)
        {
            Ids.Add(id);
            UpdateRequest = request;
            return Task.FromResult(UpdateResult);
        }

        public Task<ServiceResult> DeleteMemberAsync(long id)
        {
            Ids.Add(id);
            return Task.FromResult(DeleteResult);
        }
    }

    private sealed class FakeMemberMembershipsService : IMemberMembershipsService
    {
        public List<MemberMembershipResponse> ListResult { get; init; } = [];
        public ServiceResult<MemberMembershipResponse> GetResult { get; init; } = null!;
        public ServiceResult<MemberMembershipResponse> CreateResult { get; init; } = null!;
        public ServiceResult UpdateResult { get; init; } = null!;
        public ServiceResult DeleteResult { get; init; } = null!;
        public ServiceResult<SetMembershipBillingResponse> BillingResult { get; init; } = null!;
        public ServiceResult EndResult { get; init; } = null!;
        public List<long> Ids { get; } = [];
        public CreateMemberMembershipRequest? CreateRequest { get; private set; }
        public UpdateMemberMembershipRequest? UpdateRequest { get; private set; }
        public SetMembershipBillingRequest? BillingRequest { get; private set; }
        public EndMembershipRequest? EndRequest { get; private set; }

        public Task<List<MemberMembershipResponse>> GetMembershipsAsync() =>
            Task.FromResult(ListResult);

        public Task<MemberMembershipResponse?> GetCurrentMemberMembershipAsync() =>
            throw new NotSupportedException();

        public Task<ServiceResult<MemberMembershipResponse>> GetMembershipAsync(long id)
        {
            Ids.Add(id);
            return Task.FromResult(GetResult);
        }

        public Task<ServiceResult<MemberMembershipResponse>> CreateMembershipAsync(
            CreateMemberMembershipRequest request)
        {
            CreateRequest = request;
            return Task.FromResult(CreateResult);
        }

        public Task<ServiceResult> UpdateMembershipAsync(
            long id,
            UpdateMemberMembershipRequest request)
        {
            Ids.Add(id);
            UpdateRequest = request;
            return Task.FromResult(UpdateResult);
        }

        public Task<ServiceResult> DeleteMembershipAsync(long id)
        {
            Ids.Add(id);
            return Task.FromResult(DeleteResult);
        }

        public Task<ServiceResult<SetMembershipBillingResponse>> SetBillingAsync(
            long id,
            SetMembershipBillingRequest request)
        {
            Ids.Add(id);
            BillingRequest = request;
            return Task.FromResult(BillingResult);
        }

        public Task<ServiceResult> EndMembershipAsync(long id, EndMembershipRequest request)
        {
            Ids.Add(id);
            EndRequest = request;
            return Task.FromResult(EndResult);
        }
    }
}
