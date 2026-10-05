using AutoMapper;
using FitnessStudio.Api.Dtos.Bookings;
using FitnessStudio.Api.Entities;

namespace FitnessStudio.Api.Profiles;

public class BookingProfile : Profile
{
    public BookingProfile()
    {
        CreateMap<Booking, BookingResponse>()
            .ForMember(destination => destination.MemberFirstName, options => options.MapFrom(source => source.Member.FirstName))
            .ForMember(destination => destination.MemberLastName, options => options.MapFrom(source => source.Member.LastName))
            .ForMember(destination => destination.ClassTypeId, options => options.MapFrom(source => source.ClassSession.ClassTypeId))
            .ForMember(destination => destination.ClassTypeName, options => options.MapFrom(source => source.ClassSession.ClassType.Name))
            .ForMember(destination => destination.TrainerId, options => options.MapFrom(source => source.ClassSession.TrainerId))
            .ForMember(destination => destination.TrainerFirstName, options => options.MapFrom(source => source.ClassSession.Trainer.FirstName))
            .ForMember(destination => destination.TrainerLastName, options => options.MapFrom(source => source.ClassSession.Trainer.LastName))
            .ForMember(destination => destination.ClassSessionStartsAt, options => options.MapFrom(source => source.ClassSession.StartsAt))
            .ForMember(destination => destination.ClassSessionEndsAt, options => options.MapFrom(source => source.ClassSession.EndsAt));

        CreateMap<CreateBookingRequest, Booking>();
    }
}
