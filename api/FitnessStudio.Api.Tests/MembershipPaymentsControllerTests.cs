using System.Reflection;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembershipPaymentsControllerTests
{
    [Fact]
    public async Task ReadEndpointsReturnServiceValuesAndForwardFilters()
    {
        var payment = Payment(7, "pending");
        var service = new FakeMembershipPaymentsService
        {
            MineResult = [payment],
            AllResult = [payment],
            SummaryResult = new MembershipPaymentSummaryResponse(1, 2, 3, 4)
        };
        var controller = new MembershipPaymentsController(service);

        var mine = Assert.IsType<OkObjectResult>((await controller.Mine()).Result);
        var all = Assert.IsType<OkObjectResult>((await controller.All("reported", 19)).Result);
        var summary = Assert.IsType<OkObjectResult>((await controller.Summary()).Result);

        Assert.Same(service.MineResult, mine.Value);
        Assert.Same(service.AllResult, all.Value);
        Assert.Same(service.SummaryResult, summary.Value);
        Assert.Equal("reported", service.LastView);
        Assert.Equal(19, service.LastMemberId);
    }

    [Fact]
    public async Task GetReturnsValueAndMapsFailure()
    {
        var service = new FakeMembershipPaymentsService
        {
            GetResult = ServiceResult<MembershipPaymentResponse>.Success(Payment(7, "pending"))
        };
        var controller = new MembershipPaymentsController(service);

        var success = Assert.IsType<OkObjectResult>((await controller.Get(7)).Result);
        Assert.Equal(7, Assert.IsType<MembershipPaymentResponse>(success.Value).Id);
        Assert.Equal(7, service.LastId);

        service.GetResult = ServiceResult<MembershipPaymentResponse>.NotFound("Payment not found.", "Missing.");
        var failure = Assert.IsType<ObjectResult>((await controller.Get(8)).Result);
        Assert.Equal(StatusCodes.Status404NotFound, failure.StatusCode);
        Assert.Equal(8, service.LastId);
    }

    [Theory]
    [InlineData("report")]
    [InlineData("confirm")]
    [InlineData("reject")]
    [InlineData("reopen")]
    public async Task MutationsReturnNoContentAndForwardId(string action)
    {
        var service = new FakeMembershipPaymentsService();
        var controller = new MembershipPaymentsController(service);

        var result = action switch
        {
            "report" => await controller.Report(23),
            "confirm" => await controller.Confirm(23),
            "reject" => await controller.Reject(23),
            _ => await controller.Reopen(23)
        };

        Assert.IsType<NoContentResult>(result);
        Assert.Equal(23, service.LastId);
        Assert.Equal(action, service.LastMutation);
    }

    [Fact]
    public async Task MutationMapsConflict()
    {
        var service = new FakeMembershipPaymentsService
        {
            MutationResult = ServiceResult.Conflict("Invalid transition.", "Cannot change status.")
        };
        var controller = new MembershipPaymentsController(service);

        var result = Assert.IsType<ObjectResult>(await controller.Confirm(4));

        Assert.Equal(StatusCodes.Status409Conflict, result.StatusCode);
    }

    [Fact]
    public async Task BarcodeReturnsSvgAndMapsFailure()
    {
        var service = new FakeMembershipPaymentsService
        {
            Hub3Result = ServiceResult<string>.Success("HRVHUB30\nEUR\n000000000007000\n")
        };
        var controller = new MembershipPaymentsController(service);

        var success = Assert.IsType<ContentResult>(await controller.Barcode(11));
        Assert.StartsWith("image/svg+xml", success.ContentType);
        Assert.Contains("<svg", success.Content);
        Assert.Equal(11, service.LastId);

        service.Hub3Result = ServiceResult<string>.Forbidden("Forbidden.", "Wrong member.");
        var failure = Assert.IsType<ObjectResult>(await controller.Barcode(12));
        Assert.Equal(StatusCodes.Status403Forbidden, failure.StatusCode);
    }

    [Fact]
    public void AuthorizationContractRequiresAdminOnlyForAdministrativeActions()
    {
        var type = typeof(MembershipPaymentsController);
        Assert.NotNull(type.GetCustomAttribute<AuthorizeAttribute>());

        foreach (var name in new[] { nameof(MembershipPaymentsController.All), nameof(MembershipPaymentsController.Summary), nameof(MembershipPaymentsController.Confirm), nameof(MembershipPaymentsController.Reject), nameof(MembershipPaymentsController.Reopen) })
        {
            Assert.Equal(AuthRoles.Admin, type.GetMethod(name)!.GetCustomAttribute<AuthorizeAttribute>()?.Roles);
        }

        foreach (var name in new[] { nameof(MembershipPaymentsController.Mine), nameof(MembershipPaymentsController.Get), nameof(MembershipPaymentsController.Report), nameof(MembershipPaymentsController.Barcode) })
        {
            Assert.Null(type.GetMethod(name)!.GetCustomAttribute<AuthorizeAttribute>());
        }
    }

    private static MembershipPaymentResponse Payment(long id, string status) => new(
        id, 2, 3, "Ana Horvat", "Mjesečni", new DateOnly(2026, 10, 1),
        new DateOnly(2026, 11, 1), new DateOnly(2026, 10, 1), 70, 70, "EUR",
        status, false, "Studio", "HR1723600001101234565", "HR00", "123", "Članarina",
        null, null, $"/api/membership-payments/{id}/barcode");

    private sealed class FakeMembershipPaymentsService : IMembershipPaymentsService
    {
        public List<MembershipPaymentResponse> MineResult { get; set; } = [];
        public List<MembershipPaymentResponse> AllResult { get; set; } = [];
        public MembershipPaymentSummaryResponse SummaryResult { get; set; } = new(0, 0, 0, 0);
        public ServiceResult<MembershipPaymentResponse> GetResult { get; set; } = ServiceResult<MembershipPaymentResponse>.NotFound("Missing.", "Missing.");
        public ServiceResult MutationResult { get; set; } = ServiceResult.Success();
        public ServiceResult<string> Hub3Result { get; set; } = ServiceResult<string>.NotFound("Missing.", "Missing.");
        public string? LastView { get; private set; }
        public long? LastMemberId { get; private set; }
        public long LastId { get; private set; }
        public string? LastMutation { get; private set; }

        public Task<List<MembershipPaymentResponse>> GetMineAsync() => Task.FromResult(MineResult);
        public Task<List<MembershipPaymentResponse>> GetAllAsync(string? view, long? memberId) { LastView = view; LastMemberId = memberId; return Task.FromResult(AllResult); }
        public Task<ServiceResult<MembershipPaymentResponse>> GetAsync(long id) { LastId = id; return Task.FromResult(GetResult); }
        public Task<MembershipPaymentSummaryResponse> GetSummaryAsync() => Task.FromResult(SummaryResult);
        public Task<ServiceResult> ReportAsync(long id) => Mutation(id, "report");
        public Task<ServiceResult> ConfirmAsync(long id) => Mutation(id, "confirm");
        public Task<ServiceResult> RejectReportAsync(long id) => Mutation(id, "reject");
        public Task<ServiceResult> ReopenAsync(long id) => Mutation(id, "reopen");
        public Task<ServiceResult<string>> GetHub3PayloadAsync(long id) { LastId = id; return Task.FromResult(Hub3Result); }
        private Task<ServiceResult> Mutation(long id, string action) { LastId = id; LastMutation = action; return Task.FromResult(MutationResult); }
    }
}
