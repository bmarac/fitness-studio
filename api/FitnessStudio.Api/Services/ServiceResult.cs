namespace FitnessStudio.Api.Services;

public record ServiceResult(ServiceResultStatus Status, ServiceError? Error = null)
{
    public static ServiceResult Success()
    {
        return new ServiceResult(ServiceResultStatus.Success);
    }

    public static ServiceResult NotFound(string title, string detail)
    {
        return new ServiceResult(ServiceResultStatus.NotFound, new ServiceError(title, detail));
    }

    public static ServiceResult Forbidden(string title, string detail)
    {
        return new ServiceResult(ServiceResultStatus.Forbidden, new ServiceError(title, detail));
    }

    public static ServiceResult Conflict(string title, string detail)
    {
        return new ServiceResult(ServiceResultStatus.Conflict, new ServiceError(title, detail));
    }
}
