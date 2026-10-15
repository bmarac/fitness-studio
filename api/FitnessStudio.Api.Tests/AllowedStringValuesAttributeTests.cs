using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Validation;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class AllowedStringValuesAttributeTests
{
    private readonly TestAllowedStringValuesAttribute _attribute = new();
    private readonly ValidationContext _context = new(new object());

    [Theory]
    [InlineData(null)]
    [InlineData("active")]
    [InlineData("ACTIVE")]
    public void AcceptsNullAndAllowedValuesCaseInsensitively(string? value)
    {
        Assert.Equal(
            ValidationResult.Success,
            _attribute.GetValidationResult(value, _context));
    }

    [Fact]
    public void RejectsUnknownValuesWithTheConfiguredNameAndAllowedList()
    {
        var result = _attribute.GetValidationResult("blocked", _context);

        Assert.Equal(
            "Test value must be one of: active, inactive.",
            result!.ErrorMessage);
    }

    private sealed class TestAllowedStringValuesAttribute
        : AllowedStringValuesAttribute
    {
        public TestAllowedStringValuesAttribute()
            : base(
                "Test value",
                ["active", "inactive"],
                value => value.Equals("active", StringComparison.OrdinalIgnoreCase) ||
                    value.Equals("inactive", StringComparison.OrdinalIgnoreCase))
        {
        }
    }
}
