import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/auth/access_token_provider.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/services/secure_access_token_provider.dart';
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
import '../features/bookings/domain/usecases/get_class_session_bookings.dart';
import '../features/bookings/domain/usecases/update_booking_status.dart';
import '../features/class_sessions/data/datasources/class_sessions_remote_data_source.dart';
import '../features/class_sessions/data/repositories/class_sessions_repository_impl.dart';
import '../features/class_sessions/domain/repositories/class_sessions_repository.dart';
import '../features/class_sessions/domain/usecases/cancel_class_session.dart';
import '../features/class_sessions/domain/usecases/get_class_session.dart';
import '../features/class_sessions/domain/usecases/get_class_sessions.dart';
import '../features/class_sessions/domain/usecases/get_my_class_sessions.dart';
import '../features/profile/data/datasources/profile_remote_data_source.dart';
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
    ..registerLazySingleton<AccessTokenProvider>(
      () => SecureAccessTokenProvider(serviceLocator<AuthLocalDataSource>()),
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
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        serviceLocator<AuthRemoteDataSource>(),
        serviceLocator<AuthLocalDataSource>(),
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
    ..registerLazySingleton<BookingsRemoteDataSource>(
      () => BookingsRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<BookingsRepository>(
      () => BookingsRepositoryImpl(serviceLocator<BookingsRemoteDataSource>()),
    )
    ..registerLazySingleton<CancelBooking>(
      () => CancelBooking(serviceLocator<BookingsRepository>()),
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
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(serviceLocator<ProfileRemoteDataSource>()),
    )
    ..registerLazySingleton<GetProfile>(
      () => GetProfile(serviceLocator<ProfileRepository>()),
    )
    ..registerLazySingleton<ProgressRemoteDataSource>(
      () => ProgressRemoteDataSource(serviceLocator<ApiClient>()),
    )
    ..registerLazySingleton<ProgressRepository>(
      () => ProgressRepositoryImpl(serviceLocator<ProgressRemoteDataSource>()),
    )
    ..registerLazySingleton<GetMemberProgress>(
      () => GetMemberProgress(serviceLocator<ProgressRepository>()),
    );
}
