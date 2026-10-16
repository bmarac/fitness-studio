using System;
using System.Collections.Generic;
using FitnessStudio.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Data;

public partial class FitnessStudioDbContext : DbContext
{
    public FitnessStudioDbContext(DbContextOptions<FitnessStudioDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<AppUser> AppUsers { get; set; }

    public virtual DbSet<AppUserStudio> AppUserStudios { get; set; }

    public virtual DbSet<AppUserRole> AppUserRoles { get; set; }

    public virtual DbSet<AppNotification> AppNotifications { get; set; }

    public virtual DbSet<AppUserDeviceToken> AppUserDeviceTokens { get; set; }

    public virtual DbSet<AppUserRefreshSession> AppUserRefreshSessions { get; set; }

    public virtual DbSet<Booking> Bookings { get; set; }

    public virtual DbSet<ClassSession> ClassSessions { get; set; }

    public virtual DbSet<ClassType> ClassTypes { get; set; }

    public virtual DbSet<MeasurementParameter> MeasurementParameters { get; set; }

    public virtual DbSet<Member> Members { get; set; }

    public virtual DbSet<MemberFixedSchedule> MemberFixedSchedules { get; set; }

    public virtual DbSet<MemberMeasurement> MemberMeasurements { get; set; }

    public virtual DbSet<MemberMeasurementValue> MemberMeasurementValues { get; set; }

    public virtual DbSet<MemberMembership> MemberMemberships { get; set; }

    public virtual DbSet<MembershipPaymentObligation> MembershipPaymentObligations { get; set; }

    public virtual DbSet<MembershipPlan> MembershipPlans { get; set; }

    public virtual DbSet<RecurringClassSchedule> RecurringClassSchedules { get; set; }

    public virtual DbSet<Studio> Studios { get; set; }

    public virtual DbSet<StudioSetting> StudioSettings { get; set; }

    public virtual DbSet<Trainer> Trainers { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AppUserRefreshSession>(entity =>
        {
            entity.ToTable("app_user_refresh_sessions");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.AppUserId);
            entity.HasIndex(e => e.IdleExpiresAt);
            entity.HasIndex(e => new { e.AppUserId, e.RevokedAt });
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AppUserId).HasColumnName("app_user_id");
            entity.Property(e => e.CurrentTokenHash).HasMaxLength(64).HasColumnName("current_token_hash");
            entity.Property(e => e.PreviousTokenHash).HasMaxLength(64).HasColumnName("previous_token_hash");
            entity.Property(e => e.PreviousTokenValidUntil).HasColumnName("previous_token_valid_until");
            entity.Property(e => e.CreatedAt).HasColumnName("created_at");
            entity.Property(e => e.LastUsedAt).HasColumnName("last_used_at");
            entity.Property(e => e.IdleExpiresAt).HasColumnName("idle_expires_at");
            entity.Property(e => e.AbsoluteExpiresAt).HasColumnName("absolute_expires_at");
            entity.Property(e => e.RevokedAt).HasColumnName("revoked_at");
            entity.HasOne(e => e.AppUser).WithMany(e => e.RefreshSessions).HasForeignKey(e => e.AppUserId);
        });

        modelBuilder.Entity<AppUserStudio>(entity =>
        {
            entity.ToTable("app_user_studios");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.AppUserId, e.StudioId }).IsUnique();
            entity.HasIndex(e => e.MemberId).IsUnique().HasFilter("member_id IS NOT NULL");
            entity.HasIndex(e => e.TrainerId).IsUnique().HasFilter("trainer_id IS NOT NULL");
            entity.Property(e => e.Id).UseIdentityAlwaysColumn().HasColumnName("id");
            entity.Property(e => e.AppUserId).HasColumnName("app_user_id");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.MemberId).HasColumnName("member_id");
            entity.Property(e => e.TrainerId).HasColumnName("trainer_id");
            entity.Property(e => e.Status).HasMaxLength(30).HasDefaultValue("active").HasColumnName("status");
            entity.Property(e => e.JoinedAt).HasDefaultValueSql("now()").HasColumnName("joined_at");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("now()").HasColumnName("updated_at");
            entity.HasOne(e => e.AppUser).WithMany(e => e.StudioMemberships).HasForeignKey(e => e.AppUserId);
            entity.HasOne(e => e.Studio).WithMany(e => e.AppUserStudios).HasForeignKey(e => e.StudioId);
            entity.HasOne(e => e.Member).WithOne(e => e.AppUserStudio).HasForeignKey<AppUserStudio>(e => e.MemberId);
            entity.HasOne(e => e.Trainer).WithOne(e => e.AppUserStudio).HasForeignKey<AppUserStudio>(e => e.TrainerId);
        });

        modelBuilder.Entity<AppNotification>(entity =>
        {
            entity.ToTable("app_notifications");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).UseIdentityAlwaysColumn().HasColumnName("id");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.AppUserId).HasColumnName("app_user_id");
            entity.Property(e => e.PaymentObligationId).HasColumnName("payment_obligation_id");
            entity.Property(e => e.NotificationType).HasMaxLength(50).HasColumnName("notification_type");
            entity.Property(e => e.DayOffset).HasColumnName("day_offset");
            entity.Property(e => e.Title).HasMaxLength(160).HasColumnName("title");
            entity.Property(e => e.Body).HasColumnName("body");
            entity.Property(e => e.ReadAt).HasColumnName("read_at");
            entity.Property(e => e.PushedAt).HasColumnName("pushed_at");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("now()").HasColumnName("created_at");
            entity.HasOne(e => e.AppUser).WithMany(e => e.AppNotifications).HasForeignKey(e => e.AppUserId);
            entity.HasOne(e => e.PaymentObligation).WithMany().HasForeignKey(e => e.PaymentObligationId);
            entity.HasOne(e => e.Studio).WithMany(e => e.AppNotifications).HasForeignKey(e => e.StudioId);
        });

        modelBuilder.Entity<AppUserDeviceToken>(entity =>
        {
            entity.ToTable("app_user_device_tokens");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Token).IsUnique();
            entity.Property(e => e.Id).UseIdentityAlwaysColumn().HasColumnName("id");
            entity.Property(e => e.AppUserId).HasColumnName("app_user_id");
            entity.Property(e => e.Token).HasColumnName("token");
            entity.Property(e => e.Platform).HasMaxLength(20).HasColumnName("platform");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("now()").HasColumnName("created_at");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("now()").HasColumnName("updated_at");
            entity.HasOne(e => e.AppUser).WithMany(e => e.DeviceTokens).HasForeignKey(e => e.AppUserId);
        });

        modelBuilder.Entity<AppUser>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("app_users_pkey");

            entity.ToTable("app_users");

            entity.HasIndex(e => e.Email, "app_users_email_unique").IsUnique();
            entity.HasIndex(e => e.Status, "app_users_status_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Email)
                .HasMaxLength(255)
                .HasColumnName("email");
            entity.Property(e => e.LastLoginAt).HasColumnName("last_login_at");
            entity.Property(e => e.PasswordHash).HasColumnName("password_hash");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");
        });

        modelBuilder.Entity<AppUserRole>(entity =>
        {
            entity.HasKey(e => new { e.AppUserStudioId, e.Role }).HasName("app_user_studio_roles_pkey");

            entity.ToTable("app_user_studio_roles");

            entity.HasIndex(e => e.Role, "app_user_studio_roles_role_idx");

            entity.Property(e => e.AppUserStudioId).HasColumnName("app_user_studio_id");
            entity.Property(e => e.Role)
                .HasMaxLength(30)
                .HasColumnName("role");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");

            entity.HasOne(d => d.AppUserStudio).WithMany(p => p.Roles)
                .HasForeignKey(d => d.AppUserStudioId)
                .HasConstraintName("app_user_studio_roles_app_user_studio_id_fkey");
        });

        modelBuilder.Entity<Booking>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("bookings_pkey");

            entity.ToTable("bookings");

            entity.HasIndex(e => e.ClassSessionId, "bookings_class_session_id_idx");

            entity.HasIndex(e => e.MemberId, "bookings_member_id_idx");

            entity.HasIndex(e => new { e.MemberId, e.ClassSessionId }, "bookings_one_active_per_member_session")
                .IsUnique()
                .HasFilter("((status)::text = ANY ((ARRAY['booked'::character varying, 'attended'::character varying, 'no_show'::character varying, 'waitlisted'::character varying, 'late_cancelled'::character varying])::text[]))");

            entity.HasIndex(e => e.StudioId, "bookings_studio_id_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.AttendedAt).HasColumnName("attended_at");
            entity.Property(e => e.BookedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("booked_at");
            entity.Property(e => e.BookingSource)
                .HasMaxLength(30)
                .HasDefaultValueSql("'self_service'::character varying")
                .HasColumnName("booking_source");
            entity.Property(e => e.CancelledAt).HasColumnName("cancelled_at");
            entity.Property(e => e.CancellationReason)
                .HasMaxLength(30)
                .HasColumnName("cancellation_reason");
            entity.Property(e => e.ClassSessionId).HasColumnName("class_session_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.MemberId).HasColumnName("member_id");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'booked'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.ClassSession).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.ClassSessionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("bookings_class_session_id_fkey");

            entity.HasOne(d => d.Member).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.MemberId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("bookings_member_id_fkey");

            entity.HasOne(d => d.Studio).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("bookings_studio_id_fkey");
        });

        modelBuilder.Entity<ClassSession>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("class_sessions_pkey");

            entity.ToTable("class_sessions");

            entity.HasIndex(e => new { e.RecurringScheduleId, e.StartsAt }, "class_sessions_recurring_starts_at_unique")
                .IsUnique()
                .HasFilter("(recurring_schedule_id IS NOT NULL)");

            entity.HasIndex(e => e.StartsAt, "class_sessions_starts_at_idx");

            entity.HasIndex(e => e.StudioId, "class_sessions_studio_id_idx");

            entity.HasIndex(e => new { e.StudioId, e.StartsAt, e.Id }, "class_sessions_studio_starts_at_idx");

            entity.HasIndex(e => new { e.StudioId, e.TrainerId, e.StartsAt, e.Id }, "class_sessions_studio_trainer_starts_at_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Capacity).HasColumnName("capacity");
            entity.Property(e => e.CancellationReason)
                .HasMaxLength(30)
                .HasColumnName("cancellation_reason");
            entity.Property(e => e.ClassTypeId).HasColumnName("class_type_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.EndsAt).HasColumnName("ends_at");
            entity.Property(e => e.RecurringScheduleId).HasColumnName("recurring_schedule_id");
            entity.Property(e => e.StartsAt).HasColumnName("starts_at");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'scheduled'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.TrainerId).HasColumnName("trainer_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.ClassType).WithMany(p => p.ClassSessions)
                .HasForeignKey(d => d.ClassTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("class_sessions_class_type_id_fkey");

            entity.HasOne(d => d.RecurringSchedule).WithMany(p => p.ClassSessions)
                .HasForeignKey(d => d.RecurringScheduleId)
                .HasConstraintName("class_sessions_recurring_schedule_id_fkey");

            entity.HasOne(d => d.Studio).WithMany(p => p.ClassSessions)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("class_sessions_studio_id_fkey");

            entity.HasOne(d => d.Trainer).WithMany(p => p.ClassSessions)
                .HasForeignKey(d => d.TrainerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("class_sessions_trainer_id_fkey");
        });

        modelBuilder.Entity<ClassType>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("class_types_pkey");

            entity.ToTable("class_types");

            entity.HasIndex(e => e.StudioId, "class_types_studio_id_idx");

            entity.HasIndex(e => new { e.StudioId, e.Name }, "class_types_studio_name_unique").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.DefaultCapacity).HasColumnName("default_capacity");
            entity.Property(e => e.DefaultDurationMinutes).HasColumnName("default_duration_minutes");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.DifficultyLevel)
                .HasMaxLength(30)
                .HasDefaultValueSql("'all_levels'::character varying")
                .HasColumnName("difficulty_level");
            entity.Property(e => e.Name)
                .HasMaxLength(120)
                .HasColumnName("name");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Studio).WithMany(p => p.ClassTypes)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("class_types_studio_id_fkey");
        });

        modelBuilder.Entity<MeasurementParameter>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("measurement_parameters_pkey");

            entity.ToTable("measurement_parameters");

            entity.HasIndex(e => new { e.StudioId, e.Code }, "measurement_parameters_studio_code_unique").IsUnique();

            entity.HasIndex(e => new { e.StudioId, e.Status, e.SortOrder, e.Name }, "measurement_parameters_studio_status_sort_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(80)
                .HasColumnName("code");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Name)
                .HasMaxLength(120)
                .HasColumnName("name");
            entity.Property(e => e.SortOrder).HasColumnName("sort_order");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.Unit)
                .HasMaxLength(30)
                .HasColumnName("unit");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");
            entity.HasOne(d => d.Studio).WithMany(p => p.MeasurementParameters)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_parameters_studio_id_fkey");
        });

        modelBuilder.Entity<Member>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("members_pkey");

            entity.ToTable("members");

            entity.HasIndex(e => new { e.StudioId, e.Email }, "members_studio_email_unique").IsUnique();

            entity.HasIndex(e => e.StudioId, "members_studio_id_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.DateOfBirth).HasColumnName("date_of_birth");
            entity.Property(e => e.Email)
                .HasMaxLength(255)
                .HasColumnName("email");
            entity.Property(e => e.FirstName)
                .HasMaxLength(100)
                .HasColumnName("first_name");
            entity.Property(e => e.LastName)
                .HasMaxLength(100)
                .HasColumnName("last_name");
            entity.Property(e => e.Phone)
                .HasMaxLength(50)
                .HasColumnName("phone");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Studio).WithMany(p => p.Members)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("members_studio_id_fkey");
        });

        modelBuilder.Entity<MemberFixedSchedule>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("member_fixed_schedules_pkey");

            entity.ToTable("member_fixed_schedules");

            entity.HasIndex(e => new { e.StudioId, e.MemberId, e.Status }, "member_fixed_schedules_member_idx");

            entity.HasIndex(e => new { e.MemberId, e.RecurringScheduleId }, "member_fixed_schedules_one_active_assignment")
                .IsUnique()
                .HasFilter("((status)::text = ANY ((ARRAY['active'::character varying, 'paused'::character varying])::text[]))");

            entity.HasIndex(e => new { e.RecurringScheduleId, e.Status }, "member_fixed_schedules_schedule_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.EndsOn).HasColumnName("ends_on");
            entity.Property(e => e.MemberId).HasColumnName("member_id");
            entity.Property(e => e.RecurringScheduleId).HasColumnName("recurring_schedule_id");
            entity.Property(e => e.StartsOn).HasColumnName("starts_on");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Member).WithMany(p => p.MemberFixedSchedules)
                .HasForeignKey(d => d.MemberId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_fixed_schedules_member_id_fkey");

            entity.HasOne(d => d.RecurringSchedule).WithMany(p => p.MemberFixedSchedules)
                .HasForeignKey(d => d.RecurringScheduleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_fixed_schedules_recurring_schedule_id_fkey");

            entity.HasOne(d => d.Studio).WithMany(p => p.MemberFixedSchedules)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_fixed_schedules_studio_id_fkey");
        });

        modelBuilder.Entity<MemberMeasurement>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("member_measurements_pkey");

            entity.ToTable("member_measurements");

            entity.HasIndex(e => new { e.StudioId, e.MemberId, e.MeasuredAt }, "member_measurements_member_measured_at_idx").IsDescending(false, false, true);

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.MeasuredAt).HasColumnName("measured_at");
            entity.Property(e => e.MemberId).HasColumnName("member_id");
            entity.Property(e => e.Note).HasColumnName("note");
            entity.Property(e => e.RecordedByUserId).HasColumnName("recorded_by_user_id");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Member).WithMany(p => p.MemberMeasurements)
                .HasForeignKey(d => d.MemberId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_measurements_member_id_fkey");

            entity.HasOne(d => d.RecordedByUser).WithMany(p => p.MemberMeasurements)
                .HasForeignKey(d => d.RecordedByUserId)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("member_measurements_recorded_by_user_id_fkey");

            entity.HasOne(d => d.Studio).WithMany(p => p.MemberMeasurements)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_measurements_studio_id_fkey");
        });

        modelBuilder.Entity<MemberMeasurementValue>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("member_measurement_values_pkey");

            entity.ToTable("member_measurement_values");

            entity.HasIndex(e => new { e.MeasurementId, e.ParameterId }, "member_measurement_values_measurement_parameter_unique").IsUnique();

            entity.HasIndex(e => e.ParameterId, "member_measurement_values_parameter_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.MeasurementId).HasColumnName("measurement_id");
            entity.Property(e => e.NumericValue)
                .HasPrecision(12, 4)
                .HasColumnName("numeric_value");
            entity.Property(e => e.ParameterId).HasColumnName("parameter_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Measurement).WithMany(p => p.MemberMeasurementValues)
                .HasForeignKey(d => d.MeasurementId)
                .HasConstraintName("member_measurement_values_measurement_id_fkey");

            entity.HasOne(d => d.Parameter).WithMany(p => p.MemberMeasurementValues)
                .HasForeignKey(d => d.ParameterId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_measurement_values_parameter_id_fkey");
        });

        modelBuilder.Entity<MemberMembership>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("member_memberships_pkey");

            entity.ToTable("member_memberships");

            entity.HasIndex(e => e.MemberId, "member_memberships_member_id_idx");

            entity.HasIndex(e => e.StudioId, "member_memberships_studio_id_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.EndsOn).HasColumnName("ends_on");
            entity.Property(e => e.BillingStartsOn).HasColumnName("billing_starts_on");
            entity.Property(e => e.MemberId).HasColumnName("member_id");
            entity.Property(e => e.MembershipPlanId).HasColumnName("membership_plan_id");
            entity.Property(e => e.StartsOn).HasColumnName("starts_on");
            entity.Property(e => e.NextBillingOn).HasColumnName("next_billing_on");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Member).WithMany(p => p.MemberMemberships)
                .HasForeignKey(d => d.MemberId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_memberships_member_id_fkey");

            entity.HasOne(d => d.MembershipPlan).WithMany(p => p.MemberMemberships)
                .HasForeignKey(d => d.MembershipPlanId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_memberships_membership_plan_id_fkey");

            entity.HasOne(d => d.Studio).WithMany(p => p.MemberMemberships)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("member_memberships_studio_id_fkey");
        });

        modelBuilder.Entity<MembershipPaymentObligation>(entity =>
        {
            entity.ToTable("membership_payment_obligations");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.MemberMembershipId, e.PeriodStartsOn }).IsUnique();
            entity.HasIndex(e => new { e.StudioId, e.DueOn });
            entity.HasIndex(e => new { e.StudioId, e.Status });
            entity.Property(e => e.Id).UseIdentityAlwaysColumn().HasColumnName("id");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.MemberMembershipId).HasColumnName("member_membership_id");
            entity.Property(e => e.PeriodStartsOn).HasColumnName("period_starts_on");
            entity.Property(e => e.PeriodEndsOn).HasColumnName("period_ends_on");
            entity.Property(e => e.DueOn).HasColumnName("due_on");
            entity.Property(e => e.PlanName).HasMaxLength(120).HasColumnName("plan_name");
            entity.Property(e => e.FullAmount).HasPrecision(10, 2).HasColumnName("full_amount");
            entity.Property(e => e.AmountDue).HasPrecision(10, 2).HasColumnName("amount_due");
            entity.Property(e => e.Currency).HasMaxLength(3).HasColumnName("currency");
            entity.Property(e => e.Status).HasMaxLength(30).HasDefaultValue("pending").HasColumnName("status");
            entity.Property(e => e.RecipientName).HasMaxLength(100).HasColumnName("recipient_name");
            entity.Property(e => e.Iban).HasMaxLength(34).HasColumnName("iban");
            entity.Property(e => e.PaymentModel).HasMaxLength(4).HasColumnName("payment_model");
            entity.Property(e => e.PaymentReference).HasMaxLength(22).HasColumnName("payment_reference");
            entity.Property(e => e.PaymentDescription).HasMaxLength(35).HasColumnName("payment_description");
            entity.Property(e => e.ReportedAt).HasColumnName("reported_at");
            entity.Property(e => e.ReportedByUserId).HasColumnName("reported_by_user_id");
            entity.Property(e => e.ConfirmedAt).HasColumnName("confirmed_at");
            entity.Property(e => e.ConfirmedByUserId).HasColumnName("confirmed_by_user_id");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("now()").HasColumnName("created_at");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("now()").HasColumnName("updated_at");
            entity.HasOne(e => e.MemberMembership).WithMany(e => e.PaymentObligations).HasForeignKey(e => e.MemberMembershipId);
            entity.HasOne(e => e.Studio).WithMany(e => e.MembershipPaymentObligations).HasForeignKey(e => e.StudioId);
            entity.HasOne(e => e.ReportedByUser).WithMany().HasForeignKey(e => e.ReportedByUserId);
            entity.HasOne(e => e.ConfirmedByUser).WithMany().HasForeignKey(e => e.ConfirmedByUserId);
        });

        modelBuilder.Entity<MembershipPlan>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("membership_plans_pkey");

            entity.ToTable("membership_plans");

            entity.HasIndex(e => e.StudioId, "membership_plans_studio_id_idx");

            entity.HasIndex(e => new { e.StudioId, e.Name }, "membership_plans_studio_name_unique").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Currency)
                .HasMaxLength(3)
                .HasDefaultValueSql("'EUR'::character varying")
                .HasColumnName("currency");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.BillingPeriodMonths)
                .HasDefaultValue(1)
                .HasColumnName("billing_period_months");
            entity.Property(e => e.Name)
                .HasMaxLength(120)
                .HasColumnName("name");
            entity.Property(e => e.PriceAmount)
                .HasPrecision(10, 2)
                .HasColumnName("price_amount");
            entity.Property(e => e.SessionLimit).HasColumnName("session_limit");
            entity.Property(e => e.SessionLimitPeriod)
                .HasMaxLength(30)
                .HasColumnName("session_limit_period");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Studio).WithMany(p => p.MembershipPlans)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("membership_plans_studio_id_fkey");
        });

        modelBuilder.Entity<RecurringClassSchedule>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("recurring_class_schedules_pkey");

            entity.ToTable("recurring_class_schedules");

            entity.HasIndex(e => new { e.StudioId, e.DayOfWeek, e.StartsAtTime }, "recurring_class_schedules_schedule_idx");

            entity.HasIndex(e => e.StudioId, "recurring_class_schedules_studio_id_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Capacity).HasColumnName("capacity");
            entity.Property(e => e.ClassTypeId).HasColumnName("class_type_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.DayOfWeek).HasColumnName("day_of_week");
            entity.Property(e => e.DurationMinutes).HasColumnName("duration_minutes");
            entity.Property(e => e.StartsAtTime).HasColumnName("starts_at_time");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StatusEffectiveFrom).HasColumnName("status_effective_from");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.TrainerId).HasColumnName("trainer_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");
            entity.Property(e => e.ValidFrom).HasColumnName("valid_from");
            entity.Property(e => e.ValidUntil).HasColumnName("valid_until");

            entity.HasOne(d => d.ClassType).WithMany(p => p.RecurringClassSchedules)
                .HasForeignKey(d => d.ClassTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("recurring_class_schedules_class_type_id_fkey");

            entity.HasOne(d => d.Studio).WithMany(p => p.RecurringClassSchedules)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("recurring_class_schedules_studio_id_fkey");

            entity.HasOne(d => d.Trainer).WithMany(p => p.RecurringClassSchedules)
                .HasForeignKey(d => d.TrainerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("recurring_class_schedules_trainer_id_fkey");
        });

        modelBuilder.Entity<Studio>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("studios_pkey");

            entity.ToTable("studios");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Name)
                .HasMaxLength(150)
                .HasColumnName("name");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.Timezone)
                .HasMaxLength(100)
                .HasDefaultValueSql("'Europe/Zagreb'::character varying")
                .HasColumnName("timezone");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");
        });

        modelBuilder.Entity<StudioSetting>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("studio_settings_pkey");

            entity.ToTable("studio_settings");

            entity.HasIndex(e => e.StudioId, "studio_settings_studio_id_idx");

            entity.HasIndex(e => new { e.StudioId, e.Setting }, "studio_settings_studio_setting_unique").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Setting)
                .HasMaxLength(100)
                .HasColumnName("setting");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");
            entity.Property(e => e.Value).HasColumnName("value");
            entity.Property(e => e.ValueType)
                .HasMaxLength(30)
                .HasColumnName("value_type");

            entity.HasOne(d => d.Studio).WithMany(p => p.StudioSettings)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("studio_settings_studio_id_fkey");
        });

        modelBuilder.Entity<Trainer>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("trainers_pkey");

            entity.ToTable("trainers");

            entity.HasIndex(e => new { e.StudioId, e.Email }, "trainers_studio_email_unique").IsUnique();

            entity.HasIndex(e => e.StudioId, "trainers_studio_id_idx");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Bio).HasColumnName("bio");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Email)
                .HasMaxLength(255)
                .HasColumnName("email");
            entity.Property(e => e.FirstName)
                .HasMaxLength(100)
                .HasColumnName("first_name");
            entity.Property(e => e.LastName)
                .HasMaxLength(100)
                .HasColumnName("last_name");
            entity.Property(e => e.Phone)
                .HasMaxLength(50)
                .HasColumnName("phone");
            entity.Property(e => e.Status)
                .HasMaxLength(30)
                .HasDefaultValueSql("'active'::character varying")
                .HasColumnName("status");
            entity.Property(e => e.StudioId).HasColumnName("studio_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Studio).WithMany(p => p.Trainers)
                .HasForeignKey(d => d.StudioId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("trainers_studio_id_fkey");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
