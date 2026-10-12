using System.Reflection;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

internal static class SchedulingControllerTestAssertions
{
    public static void Problem(IActionResult? action, int statusCode)
    {
        var objectResult = Assert.IsType<ObjectResult>(action);
        Assert.Equal(statusCode, objectResult.StatusCode);
        Assert.Equal(statusCode, Assert.IsType<ProblemDetails>(objectResult.Value).Status);
    }

    public static void ControllerRequiresAuthorization(Type controllerType)
    {
        Assert.NotNull(controllerType.GetCustomAttribute<AuthorizeAttribute>());
    }

    public static void MethodRequiresRole(Type controllerType, string methodName, string roles)
    {
        var attribute = controllerType
            .GetMethod(methodName)!
            .GetCustomAttribute<AuthorizeAttribute>();
        Assert.Equal(roles, attribute?.Roles);
    }

    public static void MethodHasNoRoleOverride(Type controllerType, string methodName)
    {
        Assert.Null(controllerType
            .GetMethod(methodName)!
            .GetCustomAttribute<AuthorizeAttribute>());
    }
}
