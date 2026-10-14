using AutoMapper;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Dtos.ClassSessions;
using FitnessStudio.Api.Entities;

namespace FitnessStudio.Api.Profiles;

public class ClassSessionProfile : Profile
{
    public ClassSessionProfile()
    {
        CreateMap<ClassSession, ClassSessionResponse>()
            .ForMember(destination => destination.ClassTypeName, options => options.MapFrom(source => source.ClassType.Name))
            .ForMember(destination => destination.TrainerFirstName, options => options.MapFrom(source => source.Trainer.FirstName))
            .ForMember(destination => destination.TrainerLastName, options => options.MapFrom(source => source.Trainer.LastName))
            .ForMember(destination => destination.RecurringScheduleStatus, options => options.MapFrom(source => source.RecurringSchedule == null ? null : source.RecurringSchedule.Status))
            .ForMember(destination => destination.BookedCount, options => options.MapFrom(source => source.Bookings.Count(booking => BookingStatuses.OccupiesCapacity.Contains(booking.Status))));

        CreateMap<CreateClassSessionRequest, ClassSession>();
        CreateMap<UpdateClassSessionRequest, ClassSession>();
    }
}
