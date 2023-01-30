CREATE PROC [Migration].[uspAddAddressingPatterns]
AS

INSERT INTO Party.AddressingTypes (AddressingType) VALUES
('Salutation'), ('Addressing')

INSERT INTO [Party].[PersonAddressingPatterns]
([QuestionnaireRequirementID]
,[TitleID]
,[CountryID]
,[LanguageID]
,[GenderID]
,[Pattern]
,[DefaultAddressing]
,[AddressingTypeID]
)
SELECT DISTINCT
	 pap.RequirementID AS QuestionnaireRequirementID
	,pap.PreNominalTitleID as TitleID
	,qr.CountryID
	,pap.LanguageID
	,isnull(pap.GenderID, 0) as GenderID
	,replace(pap.AddressingPattern, '@AddressingGreeting', isnull(ag.AddressingGreetingDesc, '')) as Pattern
	,cast(dap.AddressingPatternID as bit) as DefaultAddressing
	,(Select AddressingTypeID from Party.AddressingTypes where AddressingType = 'Salutation') as AddressingTypeID
from [prophet-ods].dbo.vwADDRESSING_PersonAddressingPatterns pap
inner join Requirement.Requirements q on q.RequirementID = pap.RequirementID
inner join Requirement.QuestionnaireRequirements qr on qr.RequirementID = q.RequirementID
left join Party.Titles t on t.TitleID = pap.PreNominalTitleID
left join [Prophet-ODS].dbo.RequirementAddressingGreetings rag
	inner join [Prophet-ODS].dbo.AddressingGreetings ag on ag.AddressingGreetingID = rag.AddressingGreetingID
on rag.RequirementID = q.RequirementID
left join [Prophet-ODS].dbo.DefaultAddressingPatterns dap on dap.AddressingPatternID = pap.AddressingPatternID and dap.AddressingPatternTypeID = pap.AddressingPatternTypeID
where pap.AddressingPatternTypeID = 1




INSERT INTO [Party].[PersonAddressingPatterns]
([QuestionnaireRequirementID]
,[TitleID]
,[CountryID]
,[LanguageID]
,[GenderID]
,[Pattern]
,[AddressingTypeID])
SELECT DISTINCT
	 pap.RequirementID AS QuestionnaireRequirementID
	,pap.PreNominalTitleID as TitleID
	,qr.CountryID
	,pap.LanguageID
	,isnull(pap.GenderID, 0) as GenderID
	,replace(pap.AddressingPattern, '@AddressingGreeting', isnull(ag.AddressingGreetingDesc, '')) as Pattern
	,(Select AddressingTypeID from Party.AddressingTypes where AddressingType = 'Addressing') as AddressingTypeID
from [prophet-ods].dbo.vwADDRESSING_PersonAddressingPatterns pap
inner join Requirement.Requirements q on q.RequirementID = pap.RequirementID
inner join Requirement.QuestionnaireRequirements qr on qr.RequirementID = q.RequirementID
left join Party.Titles t on t.TitleID = pap.PreNominalTitleID
left join [Prophet-ODS].dbo.RequirementAddressingGreetings rag
	inner join [Prophet-ODS].dbo.AddressingGreetings ag on ag.AddressingGreetingID = rag.AddressingGreetingID
on rag.RequirementID = q.RequirementID
left join [Prophet-ODS].dbo.DefaultAddressingPatterns dap on dap.AddressingPatternID = pap.AddressingPatternID and dap.AddressingPatternTypeID = pap.AddressingPatternTypeID
where pap.AddressingPatternTypeID = 2

update Party.PersonAddressingPatterns
set Pattern = REPLACE(Pattern, '@PreNom', '@Title')


INSERT INTO [Party].[OrganisationAddressingPatterns]
([QuestionnaireRequirementID]
,[CountryID]
,[LanguageID]
,[Pattern]
,[AddressingTypeID])
SELECT DISTINCT
	 pap.RequirementID AS QuestionnaireRequirementID
	,qr.CountryID
	,pap.LanguageID
	,replace(pap.AddressingPattern, '@AddressingGreeting', isnull(ag.AddressingGreetingDesc, '')) as Pattern
	,(Select AddressingTypeID from Party.AddressingTypes where AddressingType = 'Salutation') as AddressingTypeID
from [prophet-ods].dbo.vwADDRESSING_OrganisationAddressingPatterns pap
inner join Requirement.Requirements q on q.RequirementID = pap.RequirementID
inner join Requirement.QuestionnaireRequirements qr on qr.RequirementID = q.RequirementID
left join [Prophet-ODS].dbo.RequirementAddressingGreetings rag
	inner join [Prophet-ODS].dbo.AddressingGreetings ag on ag.AddressingGreetingID = rag.AddressingGreetingID
on rag.RequirementID = q.RequirementID
left join [Prophet-ODS].dbo.DefaultAddressingPatterns dap on dap.AddressingPatternID = pap.AddressingPatternID and dap.AddressingPatternTypeID = pap.AddressingPatternTypeID
where pap.AddressingPatternTypeID = 1



INSERT INTO [Sample].[Party].[OrganisationAddressingPatterns]
           ([QuestionnaireRequirementID]
           ,[CountryID]
           ,[LanguageID]
           ,[Pattern]
           ,[AddressingTypeID])
SELECT DISTINCT
	 pap.RequirementID AS QuestionnaireRequirementID
	,qr.CountryID
	,pap.LanguageID
	,replace(pap.AddressingPattern, '@AddressingGreeting', isnull(ag.AddressingGreetingDesc, '')) as Pattern
	,(Select AddressingTypeID from Party.AddressingTypes where AddressingType = 'Addressing') as AddressingTypeID
from [prophet-ods].dbo.vwADDRESSING_OrganisationAddressingPatterns pap
inner join Requirement.Requirements q on q.RequirementID = pap.RequirementID
inner join Requirement.QuestionnaireRequirements qr on qr.RequirementID = q.RequirementID
left join [Prophet-ODS].dbo.RequirementAddressingGreetings rag
	inner join [Prophet-ODS].dbo.AddressingGreetings ag on ag.AddressingGreetingID = rag.AddressingGreetingID
on rag.RequirementID = q.RequirementID
left join [Prophet-ODS].dbo.DefaultAddressingPatterns dap on dap.AddressingPatternID = pap.AddressingPatternID and dap.AddressingPatternTypeID = pap.AddressingPatternTypeID
where pap.AddressingPatternTypeID = 2




		update Party.PersonAddressingPatterns
		set Pattern = 'Sehr geehrter Herr @LastName'
		where CountryID = 200
		and LanguageID = 168
		and GenderID = 1
		and AddressingTypeID = 1