using AutoMapper;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Entities;

namespace FitnessStudio.Api.Profiles;

public class MemberProfile : Profile
{
    public MemberProfile()
    {
        CreateMap<Member, MemberResponse>();
        CreateMap<CreateMemberRequest, Member>();
        CreateMap<UpdateMemberRequest, Member>();
    }
}
