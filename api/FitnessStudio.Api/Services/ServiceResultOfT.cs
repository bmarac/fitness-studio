namespace FitnessStudio.Api.Services;

public record ServiceResult<T>(ServiceResultStatus Status, T? Value = default, ServiceError? Error = null)
{
    public static ServiceResult<T> Success(T value)
    {
        return new ServiceResult<T>(ServiceResultStatus.Success, value);
    }

    public static ServiceResult<T> NotFound(string title, string detail)
    {
        return new ServiceResult<T>(ServiceResultStatus.NotFound, default, new ServiceError(title, detail));
    }

    public static ServiceResult<T> Unauthorized(string title, string detail)
    {
        return new ServiceResult<T>(ServiceResultStatus.Unauthorized, default, new ServiceError(title, detail));
    }

    public static ServiceResult<T> Conflict(string title, string detail)
    {
        return new ServiceResult<T>(ServiceResultStatus.Conflict, default, new ServiceError(title, detail));
    }
}
