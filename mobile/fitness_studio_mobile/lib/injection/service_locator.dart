import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/auth/access_token_provider.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/notifications/push_notifications_service.dart';
import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/services/auth_session_coordinator.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login.dart';
import '../features/auth/domain/usecases/logout.dart';
import '../features/auth/domain/usecases/restore_session.dart';
import '../features/bookings/data/datasources/bookings_remote_data_source.dart';
import '../features/bookings/data/repositories/bookings_repository_impl.dart';
import '../features/bookings/domain/repositories/bookings_repository.dart';
import '../features/bookings/domain/usecases/cancel_booking.dart';
import '../features/bookings/domain/usecases/cancel_fixed_schedule.dart';
import '../features/bookings/domain/usecases/create_booking.dart';
import '../features/bookings/domain/usecases/get_bookings.dart';
import '../features/bookings/domain/usecases/get_member_bookings_page.dart';
import '../features/bookings/domain/usecases/get_class_session_bookings.dart';
import '../features/bookings/domain/usecases/update_booking_status.dart';
import '../features/class_sessions/data/datasources/class_sessions_remote_data_source.dart';
import '../features/class_sessions/data/repositories/class_sessions_repository_impl.dart';
import '../features/class_sessions/domain/repositories/class_sessions_repository.dart';
import '../features/class_sessions/domain/usecases/cancel_class_session.dart';
import '../features/class_sessions/domain/usecases/get_class_session.dart';
import '../features/class_sessions/domain/usecases/get_class_sessions.dart';
import '../features/class_sessions/domain/usecases/get_class_session_workouts_page.dart';
import '../features/class_sessions/domain/usecases/get_my_class_sessions.dart';
import '../features/class_types/data/class_types_remote_data_source.dart';
import '../features/class_types/data/class_types_repository_impl.dart';
import '../features/class_types/domain/repositories/class_types_repository.dart';
import '../features/membership_plans/data/membership_plans_remote_data_source.dart';
import '../features/membership_plans/data/membership_plans_repository_impl.dart';
import '../features/membership_plans/domain/repositories/membership_plans_repository.dart';
import '../features/member_packages/data/member_packages_remote_data_source.dart';
import '../features/member_packages/data/member_packages_repository_impl.dart';
import '../features/member_packages/domain/repositories/member_packages_repository.dart';
import '../features/profile/data/datasources/profile_remote_data_source.dart';
import '../features/payments/data/payments_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/get_profile.dart';
import '../features/progress/data/datasources/progress_remote_data_source.dart';
import '../features/progress/data/repositories/progress_repository_impl.dart';
import '../features/progress/domain/repositories/progress_repository.dart';
import '../features/progress/domain/usecases/get_member_progress.dart';
import '../features/recurring_schedules/data/datasources/recurring_schedules_remote_data_source.dart';
import '../features/recurring_schedules/data/repositories/recurring_schedules_repository_impl.dart';
import '../features/recurring_schedules/domain/repositories/recurring_schedules_repository.dart';
import '../features/recurring_schedules/domain/usecases/change_recurring_schedule_status.dart';
import '../features/recurring_schedules/domain/usecases/add_fixed_schedule_member.dart';
import '../features/recurring_schedules/domain/usecases/get_recurring_schedules.dart';
import '../features/recurring_schedules/domain/usecases/get_schedule_member_options.dart';
import '../features/recurring_schedules/domain/usecases/get_trainers.dart';
import '../features/recurring_schedules/domain/usecases/get_fixed_schedule_members.dart';
import '../features/recurring_schedules/domain/usecases/move_fixed_schedule_member.dart';
import '../features/recurring_schedules/domain/usecases/update_recurring_schedule.dart';
import '../features/studio_settings/data/configuration_items_remote_data_source.dart';
import '../features/studio_settings/data/studio_configuration_repository_impl.dart';
import '../features/studio_settings/domain/studio_configuration_repository.dart';
import '../features/trainers/data/trainers_management_remote_data_source.dart';
import '../features/trainers/data/trainers_management_repository_impl.dart';
import '../features/trainers/domain/repositories/trainers_management_repository.dart';

final serviceLocator = GetIt.instance;

Future<void> configureDependencies() async {
  serviceLocator
    ..registerLazySingleton<AppConfig>(() => AppConfig.local)
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSource(serviceLocator<FlutterSecureStorage>()),
    )
    ..registerLazySingleton<AuthSessionCoordinator>(
      () => AuthSessionCoordinator(
        config: serviceLocator<AppConfig>(),
        localDataSource: serviceLocator<AuthLocalDataSource>(),
      ),
    )
    ..registerLazySingleton<AccessTokenProvider>(
      () => serviceLocator<AuthSessionCoordinator>(),
    )
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        config: serviceLocator<AppConfig>(),
        accessTokenProvider: serviceLocator<AccessTokenProvider>(),
      ),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<PushNotificationsService>(
      () => PushNotificationsService(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        serviceLocator<AuthRemoteDataSource>(),
        serviceLocator<AuthLocalDataSource>(),
        serviceLocator<PushNotificationsService>(),
        serviceLocator<AuthSessionCoordinator>(),
      ),
    )
    ..registerLazySingleton<Login>(
      () => Login(serviceLocator<AuthRepository>()),
    )
    ..registerLazySingleton<Logout>(
      () => Logout(serviceLocator<AuthRepository>()),
    )
    ..registerLazySingleton<RestoreSession>(
      () => RestoreSession(serviceLocator<AuthRepository>()),
    )
    ..registerLazySingleton<ClassSessionsRemoteDataSource>(
      () => ClassSessionsRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<ClassSessionsRepository>(
      () => ClassSessionsRepositoryImpl(
        serviceLocator<ClassSessionsRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<GetClassSessions>(
      () => GetClassSessions(serviceLocator<ClassSessionsRepository>()),
    )
    ..registerLazySingleton<GetClassSession>(
      () => GetClassSession(serviceLocator<ClassSessionsRepository>()),
    )
    ..registerLazySingleton<GetMyClassSessions>(
      () => GetMyClassSessions(serviceLocator<ClassSessionsRepository>()),
    )
    ..registerLazySingleton<GetClassSessionWorkoutsPage>(
      () => GetClassSessionWorkoutsPage(
        serviceLocator<ClassSessionsRepository>(),
      ),
    )
    ..registerLazySingleton<CancelClassSession>(
      () => CancelClassSession(serviceLocator<ClassSessionsRepository>()),
    )
    ..registerLazySingleton<RecurringSchedulesRemoteDataSource>(
      () => RecurringSchedulesRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<RecurringSchedulesRepository>(
      () => RecurringSchedulesRepositoryImpl(
        serviceLocator<RecurringSchedulesRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<GetRecurringSchedules>(
      () =>
          GetRecurringSchedules(serviceLocator<RecurringSchedulesRepository>()),
    )
    ..registerLazySingleton<GetTrainers>(
      () => GetTrainers(serviceLocator<RecurringSchedulesRepository>()),
    )
    ..registerLazySingleton<GetScheduleMemberOptions>(
      () => GetScheduleMemberOptions(
        serviceLocator<RecurringSchedulesRepository>(),
      ),
    )
    ..registerLazySingleton<ChangeRecurringScheduleStatus>(
      () => ChangeRecurringScheduleStatus(
        serviceLocator<RecurringSchedulesRepository>(),
      ),
    )
    ..registerLazySingleton<AddFixedScheduleMember>(
      () => AddFixedScheduleMember(
        serviceLocator<RecurringSchedulesRepository>(),
      ),
    )
    ..registerLazySingleton<GetFixedScheduleMembers>(
      () => GetFixedScheduleMembers(
        serviceLocator<RecurringSchedulesRepository>(),
      ),
    )
    ..registerLazySingleton<MoveFixedScheduleMember>(
      () => MoveFixedScheduleMember(
        serviceLocator<RecurringSchedulesRepository>(),
      ),
    )
    ..registerLazySingleton<UpdateRecurringSchedule>(
      () => UpdateRecurringSchedule(
        serviceLocator<RecurringSchedulesRepository>(),
      ),
    )
    ..registerLazySingleton<BookingsRemoteDataSource>(
      () => BookingsRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<BookingsRepository>(
      () => BookingsRepositoryImpl(serviceLocator<BookingsRemoteDataSource>()),
    )
    ..registerLazySingleton<CancelBooking>(
      () => CancelBooking(serviceLocator<BookingsRepository>()),
    )
    ..registerLazySingleton<GetBookings>(
      () => GetBookings(serviceLocator<BookingsRepository>()),
    )
    ..registerLazySingleton<GetMemberBookingsPage>(
      () => GetMemberBookingsPage(serviceLocator<BookingsRepository>()),
    )
    ..registerLazySingleton<CancelFixedSchedule>(
      () => CancelFixedSchedule(serviceLocator<BookingsRepository>()),
    )
    ..registerLazySingleton<CreateBooking>(
      () => CreateBooking(serviceLocator<BookingsRepository>()),
    )
    ..registerLazySingleton<GetClassSessionBookings>(
      () => GetClassSessionBookings(serviceLocator<BookingsRepository>()),
    )
    ..registerLazySingleton<UpdateBookingStatus>(
      () => UpdateBookingStatus(serviceLocator<BookingsRepository>()),
    )
    ..registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<PaymentsRemoteDataSource>(
      () => PaymentsRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<MembershipPlansRemoteDataSource>(
      () => MembershipPlansRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<MembershipPlansRepository>(
      () => MembershipPlansRepositoryImpl(
        serviceLocator<MembershipPlansRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<MemberPackagesRemoteDataSource>(
      () => MemberPackagesRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<MemberPackagesRepository>(
      () => MemberPackagesRepositoryImpl(
        serviceLocator<MemberPackagesRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(serviceLocator<ProfileRemoteDataSource>()),
    )
    ..registerLazySingleton<GetProfile>(
      () => GetProfile(serviceLocator<ProfileRepository>()),
    )
    ..registerLazySingleton<TrainersManagementRemoteDataSource>(
      () => TrainersManagementRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<TrainersManagementRepository>(
      () => TrainersManagementRepositoryImpl(
        serviceLocator<TrainersManagementRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<ProgressRemoteDataSource>(
      () => ProgressRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<ProgressRepository>(
      () => ProgressRepositoryImpl(serviceLocator<ProgressRemoteDataSource>()),
    )
    ..registerLazySingleton<GetMemberProgress>(
      () => GetMemberProgress(serviceLocator<ProgressRepository>()),
    )
    ..registerLazySingleton<ClassTypesDataSource>(
      () => ClassTypesRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<ClassTypesRepository>(
      () => ClassTypesRepositoryImpl(serviceLocator<ClassTypesDataSource>()),
    )
    ..registerLazySingleton<ConfigurationItemsRemoteDataSource>(
      () => ConfigurationItemsRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<StudioConfigurationRepository>(
      () => StudioConfigurationRepositoryImpl(
        serviceLocator<ConfigurationItemsRemoteDataSource>(),
      ),
    );
}
