using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Dtos.Bookings;
using FitnessStudio.Api.Dtos.ClassSessions;
using FitnessStudio.Api.Validation;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class SchedulingStatusValidationTests
{
    [Fact]
    public void BookingStatusAcceptsKnownValuesCaseInsensitively()
    {
        var attribute = new AllowedBookingStatusAttribute();
        var context = ValidationContext();

        foreach (var status in BookingStatuses.ManuallyAssignable)
        {
            Assert.Null(attribute.GetValidationResult(status, context));
            Assert.Null(attribute.GetValidationResult(status.ToUpperInvariant(), context));
        }
    }

    [Fact]
    public void BookingStatusAllowsNullForRequiredAttributeToHandle()
    {
        var attribute = new AllowedBookingStatusAttribute();

        Assert.Null(attribute.GetValidationResult(null, ValidationContext()));
    }

    [Fact]
    public void BookingRequestRejectsUnsupportedStatusWithAllowedValues()
    {
        var request = new UpdateBookingStatusRequest { Status = "unknown" };
        var results = Validate(request);

        var error = Assert.Single(results);
        Assert.Contains("Status must be one of", error.ErrorMessage);
        foreach (var status in BookingStatuses.ManuallyAssignable)
        {
            Assert.Contains(status, error.ErrorMessage);
        }
    }

    [Fact]
    public void BookingRequestRejectsSystemManagedLateCancellationStatus()
    {
        var request = new UpdateBookingStatusRequest
        {
            Status = BookingStatuses.LateCancelled
        };

        Assert.Single(Validate(request));
    }

    [Fact]
    public void ClassSessionStatusAcceptsKnownValuesCaseInsensitively()
    {
        var attribute = new AllowedClassSessionStatusAttribute();
        var context = ValidationContext();

        foreach (var status in ClassSessionStatuses.All)
        {
            Assert.Null(attribute.GetValidationResult(status, context));
            Assert.Null(attribute.GetValidationResult(status.ToUpperInvariant(), context));
        }
    }

    [Fact]
    public void ClassSessionStatusAllowsNullForRequiredAttributeToHandle()
    {
        var attribute = new AllowedClassSessionStatusAttribute();

        Assert.Null(attribute.GetValidationResult(null, ValidationContext()));
    }

    [Fact]
    public void ClassSessionRequestRejectsUnsupportedStatusWithAllowedValues()
    {
        var request = new UpdateClassSessionRequest
        {
            ClassTypeId = 1,
            TrainerId = 1,
            StartsAt = new DateTime(2026, 10, 13, 17, 0, 0, DateTimeKind.Utc),
            EndsAt = new DateTime(2026, 10, 13, 18, 0, 0, DateTimeKind.Utc),
            Capacity = 10,
            Status = "unknown"
        };
        var results = Validate(request);

        var error = Assert.Single(results);
        Assert.Contains("Status must be one of", error.ErrorMessage);
        foreach (var status in ClassSessionStatuses.All)
        {
            Assert.Contains(status, error.ErrorMessage);
        }
    }

    private static ValidationContext ValidationContext()
        => new(new object());

    private static List<ValidationResult> Validate(object value)
    {
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(value, new ValidationContext(value), results, true);
        return results;
    }
}
