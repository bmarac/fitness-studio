using AutoMapper;
using FitnessStudio.Api.Dtos.Trainers;
using FitnessStudio.Api.Entities;

namespace FitnessStudio.Api.Profiles;

public class TrainerProfile : Profile
{
    public TrainerProfile()
    {
        CreateMap<Trainer, TrainerResponse>();
        CreateMap<CreateTrainerRequest, Trainer>();
        CreateMap<UpdateTrainerRequest, Trainer>();
    }
}
