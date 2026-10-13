using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.MembershipPlans;

public class CreateMembershipPlanRequest
{
    [Required]
    [StringLength(120)]
    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    [Range(1, 1)]
    public int BillingPeriodMonths { get; set; } = 1;

    [Range(1, int.MaxValue)]
    public int? SessionLimit { get; set; }

    [StringLength(30)]
    public string? SessionLimitPeriod { get; set; }

    [Range(
        typeof(decimal),
        "0",
        "99999999.99",
        ParseLimitsInInvariantCulture = true)]
    public decimal PriceAmount { get; set; }

    [Required]
    [StringLength(3, MinimumLength = 3)]
    [RegularExpression("^[A-Z]{3}$")]
    public string Currency { get; set; } = "EUR";

    [Required]
    [StringLength(30)]
    public string Status { get; set; } = "active";
}
