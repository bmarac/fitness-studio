using AutoMapper;
using FitnessStudio.Api.Dtos.ClassTypes;
using FitnessStudio.Api.Entities;

namespace FitnessStudio.Api.Profiles;

public class ClassTypeProfile : Profile
{
    public ClassTypeProfile()
    {
        CreateMap<ClassType, ClassTypeResponse>();
        CreateMap<CreateClassTypeRequest, ClassType>();
        CreateMap<UpdateClassTypeRequest, ClassType>();
    }
}
