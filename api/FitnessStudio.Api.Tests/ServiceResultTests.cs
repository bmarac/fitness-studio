using FitnessStudio.Api.Services;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ServiceResultTests
{
    [Fact]
    public void GenericFactoriesCreateExpectedResults()
    {
        var success = ServiceResult<string>.Success("value");
        var unauthorized = ServiceResult<string>.Unauthorized("Unauthorized", "Sign in again.");
        var notFound = ServiceResult<string>.NotFound("Missing", "Item was not found.");
        var conflict = ServiceResult<string>.Conflict("Conflict", "Item already exists.");

        Assert.Equal(ServiceResultStatus.Success, success.Status);
        Assert.Equal("value", success.Value);
        Assert.Null(success.Error);
        AssertFailure(unauthorized, ServiceResultStatus.Unauthorized, "Unauthorized", "Sign in again.");
        AssertFailure(notFound, ServiceResultStatus.NotFound, "Missing", "Item was not found.");
        AssertFailure(conflict, ServiceResultStatus.Conflict, "Conflict", "Item already exists.");
    }

    [Fact]
    public void NonGenericFactoriesCreateExpectedResults()
    {
        var success = ServiceResult.Success();
        var forbidden = ServiceResult.Forbidden("Forbidden", "Access is denied.");
        var notFound = ServiceResult.NotFound("Missing", "Item was not found.");
        var conflict = ServiceResult.Conflict("Conflict", "Item already exists.");

        Assert.Equal(ServiceResultStatus.Success, success.Status);
        Assert.Null(success.Error);
        AssertFailure(forbidden, ServiceResultStatus.Forbidden, "Forbidden", "Access is denied.");
        AssertFailure(notFound, ServiceResultStatus.NotFound, "Missing", "Item was not found.");
        AssertFailure(conflict, ServiceResultStatus.Conflict, "Conflict", "Item already exists.");
    }

    private static void AssertFailure<T>(
        ServiceResult<T> result,
        ServiceResultStatus status,
        string title,
        string detail)
    {
        Assert.Equal(status, result.Status);
        Assert.Null(result.Value);
        Assert.Equal(title, result.Error?.Title);
        Assert.Equal(detail, result.Error?.Detail);
    }

    private static void AssertFailure(
        ServiceResult result,
        ServiceResultStatus status,
        string title,
        string detail)
    {
        Assert.Equal(status, result.Status);
        Assert.Equal(title, result.Error?.Title);
        Assert.Equal(detail, result.Error?.Detail);
    }
}
