using System.Text;
using FitnessStudio.Api.Configuration;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Auth;
using FitnessStudio.Api.Services.Bookings;
using FitnessStudio.Api.Services.ClassSessions;
using FitnessStudio.Api.Services.ClassTypes;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.Members;
using FitnessStudio.Api.Services.MemberFixedSchedules;
using FitnessStudio.Api.Services.MemberMemberships;
using FitnessStudio.Api.Services.MemberMeasurements;
using FitnessStudio.Api.Services.MeasurementParameters;
using FitnessStudio.Api.Services.MembershipPlans;
using FitnessStudio.Api.Services.Profile;
using FitnessStudio.Api.Services.RecurringClassSchedules;
using FitnessStudio.Api.Services.StudioSettings;
using FitnessStudio.Api.Services.Studios;
using FitnessStudio.Api.Services.Trainers;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddProblemDetails();
builder.Services.Configure<JwtOptions>(builder.Configuration.GetRequiredSection(JwtOptions.SectionName));
builder.Services.Configure<DevelopmentSeedUserOptions>(
    builder.Configuration.GetSection(DevelopmentSeedUserOptions.SectionName));

var jwtOptions = builder.Configuration.GetRequiredSection(JwtOptions.SectionName).Get<JwtOptions>()
    ?? throw new InvalidOperationException("JWT configuration is missing.");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtOptions.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.SigningKey)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });
builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = options.DefaultPolicy;
});
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var problemDetails = new ValidationProblemDetails(context.ModelState)
        {
            Status = StatusCodes.Status400BadRequest,
            Title = "Validation failed.",
            Detail = "One or more request fields are invalid.",
            Instance = context.HttpContext.Request.Path
        };

        return new BadRequestObjectResult(problemDetails);
    };
});
builder.Services.AddAutoMapper(_ => { }, typeof(Program).Assembly);
builder.Services.AddDbContext<FitnessStudioDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IPasswordHasher<AppUser>, PasswordHasher<AppUser>>();
builder.Services.AddScoped<ICurrentUserContext, CurrentUserContext>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IStudiosService, StudiosService>();
builder.Services.AddScoped<IStudioSettingsService, StudioSettingsService>();
builder.Services.AddScoped<IMembershipPlansService, MembershipPlansService>();
builder.Services.AddScoped<IMemberMembershipsService, MemberMembershipsService>();
builder.Services.AddScoped<IRecurringClassSchedulesService, RecurringClassSchedulesService>();
builder.Services.AddScoped<IMemberFixedSchedulesService, MemberFixedSchedulesService>();
builder.Services.AddScoped<IMembersService, MembersService>();
builder.Services.AddScoped<ITrainersService, TrainersService>();
builder.Services.AddScoped<IClassTypesService, ClassTypesService>();
builder.Services.AddScoped<IClassSessionsService, ClassSessionsService>();
builder.Services.AddScoped<IBookingsService, BookingsService>();
builder.Services.AddScoped<IProfileService, ProfileService>();
builder.Services.AddScoped<IMeasurementParametersService, MeasurementParametersService>();
builder.Services.AddScoped<IMemberMeasurementsService, MemberMeasurementsService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    await DevelopmentAuthSeeder.SeedAsync(app.Services);
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var exceptionFeature = context.Features.Get<IExceptionHandlerPathFeature>();

        var problemDetails = new ProblemDetails
        {
            Status = StatusCodes.Status500InternalServerError,
            Title = "An unexpected error occurred.",
            Detail = app.Environment.IsDevelopment()
                ? exceptionFeature?.Error.Message
                : "Please try again later.",
            Instance = context.Request.Path
        };

        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        context.Response.ContentType = "application/problem+json";

        await context.Response.WriteAsJsonAsync(problemDetails);
    });
});

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
