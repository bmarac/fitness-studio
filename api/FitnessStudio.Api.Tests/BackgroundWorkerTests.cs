using FitnessStudio.Api.Configuration;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MembershipPayments;
using FitnessStudio.Api.Services.Notifications;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class BackgroundWorkerTests
{
    [Fact]
    public async Task MembershipBillingWorkerProcessesImmediatelyAndDisposesItsScope()
    {
        var processor = new BillingProcessor();
        using var services = ServicesWithScoped<IMembershipBillingProcessor>(processor);
        var worker = new MembershipBillingWorker(
            services.GetRequiredService<IServiceScopeFactory>(),
            NullLogger<MembershipBillingWorker>.Instance);

        await worker.StartAsync(CancellationToken.None);
        await processor.Disposed.Task.WaitAsync(TimeSpan.FromSeconds(1));
        await worker.StopAsync(CancellationToken.None);

        Assert.Equal(1, processor.CallCount);
        Assert.False(processor.WasCancellationRequested);
    }

    [Fact]
    public async Task MembershipBillingWorkerLogsProcessorFailure()
    {
        var expected = new InvalidOperationException("billing failed");
        var processor = new BillingProcessor(expected);
        using var services = ServicesWithScoped<IMembershipBillingProcessor>(processor);
        var logger = new RecordingLogger<MembershipBillingWorker>();
        var worker = new MembershipBillingWorker(
            services.GetRequiredService<IServiceScopeFactory>(),
            logger);

        await worker.StartAsync(CancellationToken.None);
        var entry = await logger.Entry.Task.WaitAsync(TimeSpan.FromSeconds(1));
        await worker.StopAsync(CancellationToken.None);

        Assert.Equal(LogLevel.Error, entry.Level);
        Assert.Same(expected, entry.Exception);
        Assert.Equal("Membership billing processing failed.", entry.Message);
    }

    [Fact]
    public async Task PushNotificationWorkerProcessesImmediatelyAndDisposesItsScope()
    {
        var processor = new PushProcessor();
        using var services = ServicesWithScoped<IPushNotificationProcessor>(processor);
        var worker = new PushNotificationWorker(
            services.GetRequiredService<IServiceScopeFactory>(),
            NullLogger<PushNotificationWorker>.Instance,
            PushOptions());

        await worker.StartAsync(CancellationToken.None);
        await processor.Disposed.Task.WaitAsync(TimeSpan.FromSeconds(1));
        await worker.StopAsync(CancellationToken.None);

        Assert.Equal(1, processor.CallCount);
        Assert.False(processor.WasCancellationRequested);
    }

    [Fact]
    public async Task PushNotificationWorkerLogsProcessorFailure()
    {
        var expected = new InvalidOperationException("push failed");
        var processor = new PushProcessor(expected);
        using var services = ServicesWithScoped<IPushNotificationProcessor>(processor);
        var logger = new RecordingLogger<PushNotificationWorker>();
        var worker = new PushNotificationWorker(
            services.GetRequiredService<IServiceScopeFactory>(),
            logger,
            PushOptions());

        await worker.StartAsync(CancellationToken.None);
        var entry = await logger.Entry.Task.WaitAsync(TimeSpan.FromSeconds(1));
        await worker.StopAsync(CancellationToken.None);

        Assert.Equal(LogLevel.Error, entry.Level);
        Assert.Same(expected, entry.Exception);
        Assert.Equal("Push notification processing failed.", entry.Message);
    }

    private static ServiceProvider ServicesWithScoped<TService>(TService implementation)
        where TService : class
    {
        var services = new ServiceCollection();
        services.AddScoped<TService>(_ => implementation);
        return services.BuildServiceProvider();
    }

    private static IOptions<FirebaseMessagingOptions> PushOptions() =>
        Options.Create(new FirebaseMessagingOptions { PollSeconds = 5 });

    private sealed class BillingProcessor(Exception? exception = null)
        : WorkerProcessor(exception), IMembershipBillingProcessor
    {
        public Task ProcessAsync(CancellationToken cancellationToken = default) =>
            Process(cancellationToken);
    }

    private sealed class PushProcessor(Exception? exception = null)
        : WorkerProcessor(exception), IPushNotificationProcessor
    {
        public Task ProcessAsync(CancellationToken cancellationToken = default) =>
            Process(cancellationToken);
    }

    private abstract class WorkerProcessor(Exception? exception) : IDisposable
    {
        public int CallCount { get; private set; }
        public bool WasCancellationRequested { get; private set; }
        public TaskCompletionSource Disposed { get; } =
            new(TaskCreationOptions.RunContinuationsAsynchronously);

        protected Task Process(CancellationToken cancellationToken)
        {
            CallCount++;
            WasCancellationRequested = cancellationToken.IsCancellationRequested;
            return exception is null ? Task.CompletedTask : Task.FromException(exception);
        }

        public void Dispose() => Disposed.TrySetResult();
    }

    private sealed class RecordingLogger<T> : ILogger<T>
    {
        public TaskCompletionSource<LogEntry> Entry { get; } =
            new(TaskCreationOptions.RunContinuationsAsynchronously);

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(
            LogLevel logLevel,
            EventId eventId,
            TState state,
            Exception? exception,
            Func<TState, Exception?, string> formatter) =>
            Entry.TrySetResult(new LogEntry(logLevel, exception, formatter(state, exception)));
    }

    private sealed record LogEntry(LogLevel Level, Exception? Exception, string Message);
}
