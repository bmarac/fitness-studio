using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.Studios;

public class UpdateStudioRequest
{
    [Required]
    [StringLength(150)]
    public string Name { get; set; } = null!;

    [Required]
    [StringLength(100)]
    public string Timezone { get; set; } = null!;
}
