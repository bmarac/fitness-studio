using FitnessStudio.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Extensions;

public static class ControllerResultExtensions
{
    public static ActionResult ToActionResult<T>(this ControllerBase controller, ServiceResult<T> result)
    {
        return controller.ToActionResult(new ServiceResult(result.Status, result.Error));
    }

    public static ActionResult ToActionResult(this ControllerBase controller, ServiceResult result)
    {
        return result.Status switch
        {
            ServiceResultStatus.Unauthorized => controller.Problem(
                title: result.Error?.Title,
                detail: result.Error?.Detail,
                statusCode: StatusCodes.Status401Unauthorized),
            ServiceResultStatus.Forbidden => controller.Problem(
                title: result.Error?.Title,
                detail: result.Error?.Detail,
                statusCode: StatusCodes.Status403Forbidden),
            ServiceResultStatus.NotFound => controller.Problem(
                title: result.Error?.Title,
                detail: result.Error?.Detail,
                statusCode: StatusCodes.Status404NotFound),
            ServiceResultStatus.Conflict => controller.Problem(
                title: result.Error?.Title,
                detail: result.Error?.Detail,
                statusCode: StatusCodes.Status409Conflict),
            _ => controller.Problem(statusCode: StatusCodes.Status500InternalServerError)
        };
    }
}
