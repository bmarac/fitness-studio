namespace FitnessStudio.Api.Domain.Auth;

public static class AuthRoles
{
    public const string Admin = "admin";
    public const string Trainer = "trainer";
    public const string Member = "member";

    public const string Staff = Admin + "," + Trainer;
}
