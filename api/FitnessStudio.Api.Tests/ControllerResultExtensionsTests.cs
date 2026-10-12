using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ControllerResultExtensionsTests
{
    [Theory]
    [InlineData(ServiceResultStatus.Unauthorized, StatusCodes.Status401Unauthorized)]
    [InlineData(ServiceResultStatus.Forbidden, StatusCodes.Status403Forbidden)]
    [InlineData(ServiceResultStatus.NotFound, StatusCodes.Status404NotFound)]
    [InlineData(ServiceResultStatus.Conflict, StatusCodes.Status409Conflict)]
    public void MapsFailureStatusToProblemResponse(
        ServiceResultStatus status,
        int expectedStatusCode)
    {
        var controller = CreateController();
        var result = new ServiceResult(status, new ServiceError("Problem title", "Problem detail"));

        var action = controller.ToActionResult(result);

        AssertProblem(action, expectedStatusCode, "Problem title", "Problem detail");
    }

    [Fact]
    public void GenericFailureUsesSameMapping()
    {
        var controller = CreateController();
        var result = ServiceResult<string>.NotFound("Missing", "Item was not found.");

        var action = controller.ToActionResult(result);

        AssertProblem(action, StatusCodes.Status404NotFound, "Missing", "Item was not found.");
    }

    [Fact]
    public void UnexpectedStatusMapsToInternalServerError()
    {
        var controller = CreateController();

        var action = controller.ToActionResult(ServiceResult.Success());

        AssertProblem(action, StatusCodes.Status500InternalServerError, null, null);
    }

    private static ControllerBase CreateController()
    {
        return new TestController
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext()
            }
        };
    }

    private static void AssertProblem(
        ActionResult action,
        int statusCode,
        string? title,
        string? detail)
    {
        var objectResult = Assert.IsType<ObjectResult>(action);
        Assert.Equal(statusCode, objectResult.StatusCode);
        var problem = Assert.IsType<ProblemDetails>(objectResult.Value);
        Assert.Equal(statusCode, problem.Status);
        Assert.Equal(title, problem.Title);
        Assert.Equal(detail, problem.Detail);
    }

    private sealed class TestController : ControllerBase;
}
