CREATE PROCEDURE [Enprecis].[EnprecisExtract]
@MaxDaysSinceSelect INT
AS
SET NOCOUNT ON

/*
	Purpose:	To output into tables records selected for emprecis since param date
	
	Version		Developer			Date			Comment
	1.0			Poorvi Prasad		??/??/????		Created
	1.1			Martin Riverol		24/07/2013		BUG#9136 - Include selected F-Types in the extracted outputted
	1.2			Martin Riverol		25/07/2013		BUG#9248 - Add Jag 1 month selections to the output
	1.3			Martin Riverol		28/08/2013		BUG#9358 - New Range Rover Sport Model Variant (i.e. SALW%) missing from LR 1M output
	1.4			Chris Ross			04/09/2013		BUG 9296 - Add new Markets: EPS, ITA, FRA
	1.5			Chris Ross			20/09/2013		BUG 9296 - Missing country code being populated from Dealer table using dealer code to link.  
															   Also linking on Dealer Code for region information causing duplicates.
															   Dealer codes are not unique across markets.  Changed to use the OutletPartyID instead.
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

Begin 

-- Check @MaxDaysSinceSelect paramter supplied 



-- Get the latest Enprecis selections requirementIDs 


--declare @MaxDaysSinceSelect int 


Declare	@QuestionnaireRequirementID Int
Declare @SelectionID_J1M_UK  bigint
Declare @SelectionID_J3M_UK  bigint
Declare @SelectionID_J12M_UK  bigint
Declare @SelectionID_J24M_UK  bigint				
Declare @SelectionID_LR3M_UK  bigint
Declare @SelectionID_LR12M_UK bigint				
Declare @SelectionID_LR24M_UK bigint				
Declare @SelectionID_LR1M_UK bigint


Declare @SelectionID_J1M_AUS  bigint
Declare @SelectionID_J3M_AUS  bigint
Declare @SelectionID_J12M_AUS  bigint
Declare @SelectionID_J24M_AUS  bigint				
Declare @SelectionID_LR3M_AUS  bigint
Declare @SelectionID_LR12M_AUS bigint				
Declare @SelectionID_LR24M_AUS bigint				
Declare @SelectionID_LR1M_AUS bigint

Declare @SelectionID_J1M_RUS   bigint
Declare @SelectionID_J3M_RUS   bigint
Declare @SelectionID_J12M_RUS  bigint
Declare @SelectionID_J24M_RUS  bigint				
Declare @SelectionID_LR3M_RUS  bigint
Declare @SelectionID_LR12M_RUS bigint				
Declare @SelectionID_LR24M_RUS bigint				
Declare @SelectionID_LR1M_RUS bigint

Declare @SelectionID_J1M_CHN   bigint
Declare @SelectionID_J3M_CHN   bigint
Declare @SelectionID_J12M_CHN  bigint
Declare @SelectionID_J24M_CHN  bigint				
Declare @SelectionID_LR3M_CHN  bigint
Declare @SelectionID_LR12M_CHN bigint				
Declare @SelectionID_LR24M_CHN bigint				
Declare @SelectionID_LR1M_CHN bigint				

Declare @SelectionID_J1M_ESP bigint				-- v1.4
Declare @SelectionID_J3M_ESP bigint				
Declare @SelectionID_LR3M_ESP bigint				

Declare @SelectionID_J1M_ITA bigint				
Declare @SelectionID_J3M_ITA bigint				
Declare @SelectionID_LR3M_ITA bigint				

Declare @SelectionID_J1M_FRA bigint				
Declare @SelectionID_J3M_FRA bigint				
Declare @SelectionID_LR3M_FRA bigint	

-- Set the selectionIDs for each extract (as per Poorvi's original methodology - these are re-used later)

Set @SelectionID_J1M_UK   = (select max(r.requirementid) from requirement.requirements r join requirement.selectionrequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%UK%' and requirement like '%enprecis%UK%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J3M_UK   = (select max(r.requirementid) from requirement.requirements r join requirement.selectionrequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%UK%' and requirement like '%enprecis%UK%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J12M_UK  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%12M%UK%' and requirement like '%enprecis%UK%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J24M_UK  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%24M%UK%' and requirement like '%enprecis%UK%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_LR3M_UK  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%UK%' and requirement like '%enprecis%UK%' and requirement like '%lr%' and not(datelastrun is null))
Set @SelectionID_LR12M_UK = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%12M%UK%' and requirement like '%enprecis%UK%' and requirement like '%lr%' and not(datelastrun is null))
Set @SelectionID_LR24M_UK = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%24M%UK%' and requirement like '%enprecis%UK%' and requirement like '%lr%' and not(datelastrun is null))	
Set @SelectionID_LR1M_UK = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%UK%' and requirement like '%enprecis%UK%' and requirement like '%lr%' and not(datelastrun is null))	

Set @SelectionID_J1M_AUS   = (select max(r.requirementid) from requirement.requirements r join requirement.selectionrequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%AUS%' and requirement like '%enprecis%AUS%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J3M_AUS   = (select max(r.requirementid) from requirement.requirements r join requirement.selectionrequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%AUS%' and requirement like '%enprecis%AUS%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J12M_AUS  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%12M%AUS%' and requirement like '%enprecis%AUS%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J24M_AUS  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%24M%AUS%' and requirement like '%enprecis%AUS%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_LR3M_AUS  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%AUS%' and requirement like '%enprecis%AUS%' and requirement like '%lr%' and not(datelastrun is null))
Set @SelectionID_LR12M_AUS = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%12M%AUS%' and requirement like '%enprecis%AUS%' and requirement like '%lr%' and not(datelastrun is null))
Set @SelectionID_LR24M_AUS = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%24M%AUS%' and requirement like '%enprecis%AUS%' and requirement like '%lr%' and not(datelastrun is null))	
Set @SelectionID_LR1M_AUS = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%AUS%' and requirement like '%enprecis%AUS%' and requirement like '%lr%' and not(datelastrun is null))	

Set @SelectionID_J1M_RUS   = (select max(r.requirementid) from requirement.requirements r join requirement.selectionrequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%RUS%' and requirement like '%enprecis%RUS%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J3M_RUS   = (select max(r.requirementid) from requirement.requirements r join requirement.selectionrequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%RUS%' and requirement like '%enprecis%RUS%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J12M_RUS  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%12M%RUS%' and requirement like '%enprecis%RUS%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J24M_RUS  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%24M%RUS%' and requirement like '%enprecis%RUS%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_LR3M_RUS  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%RUS%' and requirement like '%enprecis%RUS%' and requirement like '%lr%' and not(datelastrun is null))
Set @SelectionID_LR12M_RUS = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%12M%RUS%' and requirement like '%enprecis%RUS%' and requirement like '%lr%' and not(datelastrun is null))
Set @SelectionID_LR24M_RUS = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%24M%RUS%' and requirement like '%enprecis%RUS%' and requirement like '%lr%' and not(datelastrun is null))	
Set @SelectionID_LR1M_RUS = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%RUS%' and requirement like '%enprecis%RUS%' and requirement like '%lr%' and not(datelastrun is null))	

Set @SelectionID_J1M_CHN   = (select max(r.requirementid) from requirement.requirements r join requirement.selectionrequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%CHN%' and requirement like '%enprecis%CHN%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J3M_CHN   = (select max(r.requirementid) from requirement.requirements r join requirement.selectionrequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%CHN%' and requirement like '%enprecis%CHN%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J12M_CHN  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%12M%CHN%' and requirement like '%enprecis%CHN%' and requirement like '%jag%' and not(datelastrun is null))
Set @SelectionID_J24M_CHN  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%24M%CHN%' and requirement like '%enprecis%CHN%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_LR3M_CHN  = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%CHN%' and requirement like '%enprecis%CHN%' and requirement like '%lr%' and not(datelastrun is null))
Set @SelectionID_LR12M_CHN = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%12M%CHN%' and requirement like '%enprecis%CHN%' and requirement like '%lr%' and not(datelastrun is null))
Set @SelectionID_LR24M_CHN = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%24M%CHN%' and requirement like '%enprecis%CHN%' and requirement like '%lr%' and not(datelastrun is null))	
Set @SelectionID_LR1M_CHN = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%CHN%' and requirement like '%enprecis%CHN%' and requirement like '%lr%' and not(datelastrun is null))	

Set @SelectionID_J1M_ESP = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%ESP%' and requirement like '%enprecis%ESP%' and requirement like '%jag%' and not(datelastrun is null))	-- v1.4
Set @SelectionID_J3M_ESP = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%ESP%' and requirement like '%enprecis%ESP%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_LR3M_ESP = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%ESP%' and requirement like '%enprecis%ESP%' and requirement like '%lr%' and not(datelastrun is null))	

Set @SelectionID_J1M_ITA = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%ITA%' and requirement like '%enprecis%ITA%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_J3M_ITA = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%ITA%' and requirement like '%enprecis%ITA%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_LR3M_ITA = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%ITA%' and requirement like '%enprecis%ITA%' and requirement like '%lr%' and not(datelastrun is null))	

Set @SelectionID_J1M_FRA = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%1M%FRA%' and requirement like '%enprecis%FRA%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_J3M_FRA = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%FRA%' and requirement like '%enprecis%FRA%' and requirement like '%jag%' and not(datelastrun is null))	
Set @SelectionID_LR3M_FRA = (select max(r.requirementid) from requirement.Requirements r join requirement.SelectionRequirements sr on r.requirementid = sr.requirementid where requirement like '%3M%FRA%' and requirement like '%enprecis%FRA%' and requirement like '%lr%' and not(datelastrun is null))	


-- Check the latest Enprecis selections were run within the number of days specified by @MaxDaysSinceSelect

IF (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J1M_UK)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J3M_UK)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J12M_UK)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J24M_UK)  > @MaxDaysSinceSelect			
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR3M_UK)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR12M_UK) > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR24M_UK) > @MaxDaysSinceSelect			
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR1M_UK) > @MaxDaysSinceSelect			


IF (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J1M_AUS)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J3M_AUS)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J12M_AUS)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J24M_AUS)  > @MaxDaysSinceSelect			
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR3M_AUS)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR12M_AUS) > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR24M_AUS) > @MaxDaysSinceSelect			
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR1M_AUS) > @MaxDaysSinceSelect	


IF (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J1M_CHN)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J3M_CHN)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J12M_CHN)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J24M_CHN)  > @MaxDaysSinceSelect			
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR3M_CHN)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR12M_CHN) > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR24M_CHN) > @MaxDaysSinceSelect			
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR1M_CHN) > @MaxDaysSinceSelect	


IF (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J1M_RUS)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J3M_RUS)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J12M_RUS)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J24M_RUS)  > @MaxDaysSinceSelect			
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR3M_RUS)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR12M_RUS) > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR24M_RUS) > @MaxDaysSinceSelect			
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR1M_RUS) > @MaxDaysSinceSelect	

IF (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J1M_ESP)   > @MaxDaysSinceSelect   -- 1.4
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J3M_ESP)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR3M_ESP)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J1M_ITA)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J3M_ITA)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR3M_ITA)  > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J1M_FRA)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_J3M_FRA)   > @MaxDaysSinceSelect
OR (select DATEDIFF(day, DateLastRun, getdate()) from requirement.SelectionRequirements where requirementID = @SelectionID_LR3M_FRA)  > @MaxDaysSinceSelect
BEGIN
  SET @ErrorMessage = 'No Enprecis selections were found within the selection time window of ' + convert(varchar(10), @MaxDaysSinceSelect) + ' days.'
  RAISERROR (@ErrorMessage,
			 16, -- Severity
			 1  -- State 
			)
  RETURN
END


-- Clear down Enprecis staging tables prior to loading----------------------------------------------------------

TRUNCATE TABLE Enprecis.JaguarDataUK_1M
TRUNCATE TABLE Enprecis.JaguarDataUK_3M
TRUNCATE TABLE Enprecis.JaguarDataUK_12M
TRUNCATE TABLE Enprecis.JaguarDataUK_24M				
TRUNCATE TABLE Enprecis.LandRoverDataUK_3M
TRUNCATE TABLE Enprecis.LandRoverDataUK_12M
TRUNCATE TABLE Enprecis.LandRoverDataUK_24M			
TRUNCATE TABLE Enprecis.LandRoverDataUK_1M		

-- Extract/process the data from the latest Enprecis selections ------------------------------------------------

-- set selection id for questionniare Jaguar 3M
Select	@QuestionnaireRequirementID = RequirementIDPartOf
From	requirement.RequirementRollups rr
Where	RequirementIDMadeUpOf in (Select QuestionnaireRequirementID from dbo.BrandMarketQuestionnaireSampleMetadata where SelectionName like '%Jag%3M%')

	Select distinct	CD.PartyID,
		CD.CaseID,
		Country,
		'Jaguar' as ManufacturerName,
		CD.VIN,
		CD.ChassisNumber,
		ModelDescription as FullModelDesc,
		RegistrationNumber, 
		Null DeliveryDate,
		NULL as Salutation, 
		NULL as Addressee,
		Title, 
		FirstName,
		LastName, 
		SecondLastName,
		OrganisationName,
		BuildingName, 
		SubStreet, 
		StreetNumber,
		Street, 
		SubLocality, 
		Locality, 
		Town, 
		Region, 
		PostCode,
		WorkLandlineID as telnum,
		LandlineID as telnum2,
		MobileID as telnum3,
		Emailaddress,
		Current_TimeStamp OutputDate,
		SaleType,
		Selection, 
		ModelDerivative,
		' ' as RejectionTypeID,
		' ' as RejectionID,
		DealerName,
		DealerCode,     
		DealerPartyID ,	  -- v1.5
		RegistrationDate,
		EventDate,
		OwnershipCycle,
		BuildYear as ModelYear,
		GenderID,
		SelectionRequirementID
	into #tmp_1
	From	Meta.CaseDetails CD
	Join ContactMechanism.PartyContactMechanisms PCM on CD.PartyID = PCM.PartyID
	Left Join ContactMechanism.PostalAddresses PA on CD.PostalAddressContactMechanismID = PA.ContactMechanismID
	Left Join ContactMechanism.EmailAddresses EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
	left join Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
	left join ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
	Join Vehicle.Vehicles V on CD.VIN = V.VIN
	Where	CD.SelectionRequirementID in (@SelectionID_J3M_UK,
										  @SelectionID_J3M_AUS,
										  @SelectionID_J3M_CHN,
										  @SelectionID_J3M_RUS,
										  @SelectionID_J3M_ESP,  -- 1.4
										  @SelectionID_J3M_ITA,
										  @SelectionID_J3M_FRA)
	AND CD.CaseStatusTypeID <> 2
	
	
-- set selection id for questionniare Jaguar 12M  --------------------------------------------------------
Set @QuestionnaireRequirementID = NULL
Select	@QuestionnaireRequirementID = RequirementIDPartOf
From	Requirement.RequirementRollups rr
Where	RequirementIDMadeUpOf in (Select QuestionnaireRequirementID from dbo.BrandMarketQuestionnaireSampleMetadata where SelectionName like '%Jag%12M%')

insert into #tmp_1
	Select distinct	CD.PartyID,
		CD.CaseID,
		Country,
		'Jaguar' as ManufacturerName,
		CD.VIN,
		CD.ChassisNumber,
		ModelDescription as FullModelDesc,
		RegistrationNumber, 
		Null DeliveryDate,
		NULL as Salutation, 
		NULL as Addressee,
		Title, 
		FirstName,
		LastName, 
		SecondLastName,
		OrganisationName,
		BuildingName, 
		SubStreet, 
		StreetNumber,
		Street, 
		SubLocality, 
		Locality, 
		Town, 
		Region, 
		PostCode,
		WorkLandlineID as telnum,
		LandlineID as telnum2,
		MobileID as telnum3,
		Emailaddress,
		Current_TimeStamp OutputDate,
		SaleType,
		Selection, 
		ModelDerivative,
		' ' as RejectionTypeID,
		' ' as RejectionID,
		DealerName,
		DealerCode,
		DealerPartyID ,			-- v1.5
		RegistrationDate,
		EventDate,
		OwnershipCycle,
		BuildYear as ModelYear,
		GenderID,
		SelectionRequirementID
	From	Meta.CaseDetails CD
	Join ContactMechanism.PartyContactMechanisms PCM on CD.PartyID = PCM.PartyID
	Left Join ContactMechanism.PostalAddresses PA on CD.PostalAddressContactMechanismID = PA.ContactMechanismID
	Left Join ContactMechanism.EmailAddresses EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
	left join Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
	left join ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
	Join Vehicle.Vehicles V on CD.VIN = V.VIN
	Where	CD.SelectionRequirementID in (@SelectionID_J12M_UK,@SelectionID_J12M_AUS,@SelectionID_J12M_CHN,@SelectionID_J12M_RUS)
	AND CD.CaseStatusTypeID <> 2

-- set selection id for questionniare Jaguar 24M  --------------------------------------------------------		--1.2v
Set @QuestionnaireRequirementID = NULL
Select	@QuestionnaireRequirementID = RequirementIDPartOf
From	requirement.RequirementRollups rr
Where	RequirementIDMadeUpOf in (Select QuestionnaireRequirementID from dbo.BrandMarketQuestionnaireSampleMetadata where SelectionName like '%Jag%24M%')

insert into #tmp_1
	Select distinct	CD.PartyID,
		CD.CaseID,
		Country,
		'Jaguar' as ManufacturerName,
		CD.VIN,
		CD.ChassisNumber,
		ModelDescription as FullModelDesc,
		RegistrationNumber, 
		Null DeliveryDate,
		NULL as Salutation, 
		NULL as Addressee,
		Title, 
		FirstName,
		LastName, 
		SecondLastName,
		OrganisationName,
		BuildingName, 
		SubStreet, 
		StreetNumber,
		Street, 
		SubLocality, 
		Locality, 
		Town, 
		Region, 
		PostCode,
		WorkLandlineID as telnum,
		LandlineID as telnum2,
		MobileID as telnum3,
		Emailaddress,
		Current_TimeStamp OutputDate,
		SaleType,
		Selection, 
		ModelDerivative,
		' ' as RejectionTypeID,
		' ' as RejectionID,
		DealerName,
		DealerCode,
		DealerPartyID ,			-- v1.5
		RegistrationDate,
		EventDate,
		OwnershipCycle,
		BuildYear as ModelYear,
		GenderID,
		SelectionRequirementID
	From	Meta.CaseDetails CD
	Join ContactMechanism.PartyContactMechanisms PCM on CD.PartyID = PCM.PartyID
	Left Join ContactMechanism.PostalAddresses PA on CD.PostalAddressContactMechanismID = PA.ContactMechanismID
	Left Join ContactMechanism.EmailAddresses EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
	left join Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
	left join ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
	Join Vehicle.Vehicles V on CD.VIN = V.VIN
	Where	CD.SelectionRequirementID in (@SelectionID_J24M_UK,@SelectionID_J24M_AUS,@SelectionID_J24M_CHN,@SelectionID_J24M_RUS)
	AND CD.CaseStatusTypeID <> 2


-- set selection id for questionniare Jaguar 1M
Select	@QuestionnaireRequirementID = RequirementIDPartOf
From	requirement.RequirementRollups rr
Where	RequirementIDMadeUpOf in (Select QuestionnaireRequirementID from dbo.BrandMarketQuestionnaireSampleMetadata where SelectionName like '%Jag%1M%')

	insert into #tmp_1
		Select distinct	CD.PartyID,
			CD.CaseID,
			Country,
			'Jaguar' as ManufacturerName,
			CD.VIN,
			CD.ChassisNumber,
			ModelDescription as FullModelDesc,
			RegistrationNumber, 
			Null DeliveryDate,
			NULL as Salutation, 
			NULL as Addressee,
			Title, 
			FirstName,
			LastName, 
			SecondLastName,
			OrganisationName,
			BuildingName, 
			SubStreet, 
			StreetNumber,
			Street, 
			SubLocality, 
			Locality, 
			Town, 
			Region, 
			PostCode,
			WorkLandlineID as telnum,
			LandlineID as telnum2,
			MobileID as telnum3,
			Emailaddress,
			Current_TimeStamp OutputDate,
			SaleType,
			Selection, 
			ModelDerivative,
			' ' as RejectionTypeID,
			' ' as RejectionID,
			DealerName,
			DealerCode,
			DealerPartyID ,			-- v1.5
			RegistrationDate,
			EventDate,
			OwnershipCycle,
			BuildYear as ModelYear,
			GenderID,
			SelectionRequirementID
		From	Meta.CaseDetails CD
		Join ContactMechanism.PartyContactMechanisms PCM on CD.PartyID = PCM.PartyID
		Left Join ContactMechanism.PostalAddresses PA on CD.PostalAddressContactMechanismID = PA.ContactMechanismID
		Left Join ContactMechanism.EmailAddresses EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
		left join Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
		left join ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
		Join Vehicle.Vehicles V on CD.VIN = V.VIN
		Where	CD.SelectionRequirementID in (@SelectionID_J1M_UK,
											  @SelectionID_J1M_AUS,
											  @SelectionID_J1M_CHN,
											  @SelectionID_J1M_RUS,
											  @SelectionID_J1M_ESP,  --cgr
										      @SelectionID_J1M_ITA,
										      @SelectionID_J1M_FRA)
		AND CD.CaseStatusTypeID <> 2


	
-- set selection id for questionniare Land Rover 3M  -----------------------------------------------------
Set @QuestionnaireRequirementID = NULL
Select	@QuestionnaireRequirementID = RequirementIDPartOf
From	requirement.RequirementRollups rr
Where	RequirementIDMadeUpOf in (Select QuestionnaireRequirementID from dbo.BrandMarketQuestionnaireSampleMetadata where SelectionName like '%LR%3M%')

insert into #tmp_1
	Select distinct	CD.PartyID,
		CD.CaseID,
		Country,
		'LR' as ManufacturerName,
		CD.VIN,
		CD.ChassisNumber,
		ModelDescription as FullModelDesc,
		RegistrationNumber, 
		Null DeliveryDate,
		NULL as Salutation, 
		NULL as Addressee,
		Title, 
		FirstName,
		LastName, 
		SecondLastName,
		OrganisationName,
		BuildingName, 
		SubStreet, 
		StreetNumber,
		Street, 
		SubLocality, 
		Locality, 
		Town, 
		Region, 
		PostCode,
		WorkLandlineID as telnum,
		LandlineID as telnum2,
		MobileID as telnum3,
		Emailaddress,
		Current_TimeStamp OutputDate,
		SaleType,
		Selection, 
		ModelDerivative,
		' ' as RejectionTypeID,
		' ' as RejectionID,
		DealerName,
		DealerCode,
		DealerPartyID ,			-- v1.5
		RegistrationDate,
		EventDate,
		OwnershipCycle,
		BuildYear as ModelYear,
		GenderID,
		SelectionRequirementID
	From	Meta.CaseDetails CD
	Join ContactMechanism.PartyContactMechanisms PCM on CD.PartyID = PCM.PartyID
	Left Join ContactMechanism.PostalAddresses PA on CD.PostalAddressContactMechanismID = PA.ContactMechanismID
	Left Join ContactMechanism.EmailAddresses EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
	left join Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
	left join ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
	Join Vehicle.Vehicles V on CD.VIN = V.VIN
	Where	CD.SelectionRequirementID in  (@SelectionID_LR3M_UK,
											@SelectionID_LR3M_CHN,
											@SelectionID_LR3M_RUS,
											@SelectionID_LR3M_AUS,
											@SelectionID_LR3M_ESP,  -- 1.4
											@SelectionID_LR3M_ITA,
											@SelectionID_LR3M_FRA)
	AND CD.CaseStatusTypeID <> 2


-- set selection id for questionniare Land Rover 12M  ------------------------------------------------
Set @QuestionnaireRequirementID = NULL
Select	@QuestionnaireRequirementID = RequirementIDPartOf
From	requirement.RequirementRollups rr
Where	RequirementIDMadeUpOf in (Select QuestionnaireRequirementID from dbo.BrandMarketQuestionnaireSampleMetadata where SelectionName like '%LR%12M%')

insert into #tmp_1
	Select distinct	CD.PartyID,
		CD.CaseID,
		Country,
		'LR' as ManufacturerName,
		CD.VIN,
		CD.ChassisNumber,
		ModelDescription as FullModelDesc,
		RegistrationNumber, 
		Null DeliveryDate,
		NULL as Salutation, 
		NULL as Addressee,
		Title, 
		FirstName,
		LastName, 
		SecondLastName,
		OrganisationName,
		BuildingName, 
		SubStreet, 
		StreetNumber,
		Street, 
		SubLocality, 
		Locality, 
		Town, 
		Region, 
		PostCode,
		WorkLandlineID as telnum,
		LandlineID as telnum2,
		MobileID as telnum3,
		Emailaddress,
		Current_TimeStamp OutputDate,
		SaleType,
		Selection, 
		ModelDerivative,
		' ' as RejectionTypeID,
		' ' as RejectionID,
		DealerName,
		DealerCode,
		DealerPartyID ,   -- v1.5
		RegistrationDate,
		EventDate,
		OwnershipCycle,
		BuildYear as ModelYear,
		GenderID,
		SelectionRequirementID
	From	Meta.CaseDetails CD
	Join ContactMechanism.PartyContactMechanisms PCM on CD.PartyID = PCM.PartyID
	Left Join ContactMechanism.PostalAddresses PA on CD.PostalAddressContactMechanismID = PA.ContactMechanismID
	Left Join ContactMechanism.EmailAddresses EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
	left join Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
	left join ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
	Join Vehicle.Vehicles V on CD.VIN = V.VIN
	Where	CD.SelectionRequirementID in  (@SelectionID_LR12M_UK,@SelectionID_LR12M_CHN,@SelectionID_LR12M_RUS,@SelectionID_LR12M_AUS)
	AND CD.CaseStatusTypeID <> 2

-- set selection id for questionniare Land Rover 24M  ------------------------------------------------				--1.2v
Set @QuestionnaireRequirementID = NULL
Select	@QuestionnaireRequirementID = RequirementIDPartOf
From	requirement.RequirementRollups rr
Where	RequirementIDMadeUpOf in (Select QuestionnaireRequirementID from dbo.BrandMarketQuestionnaireSampleMetadata where SelectionName like '%LR%24M%')

insert into #tmp_1
	Select distinct	CD.PartyID,
		CD.CaseID,
		Country,
		'LR' as ManufacturerName,
		CD.VIN,
		CD.ChassisNumber,
		ModelDescription as FullModelDesc,
		RegistrationNumber, 
		Null DeliveryDate,
		NULL as Salutation, 
		NULL as Addressee,
		Title, 
		FirstName,
		LastName, 
		SecondLastName,
		OrganisationName,
		BuildingName, 
		SubStreet, 
		StreetNumber,
		Street, 
		SubLocality, 
		Locality, 
		Town, 
		Region, 
		PostCode,
		WorkLandlineID as telnum,
		LandlineID as telnum2,
		MobileID as telnum3,
		Emailaddress,
		Current_TimeStamp OutputDate,
		SaleType,
		Selection, 
		ModelDerivative,
		' ' as RejectionTypeID,
		' ' as RejectionID,
		DealerName,
		DealerCode,
		DealerPartyID ,   -- v1.5
		RegistrationDate,
		EventDate,
		OwnershipCycle,
		BuildYear as ModelYear,
		GenderID,
		SelectionRequirementID
	From	Meta.CaseDetails CD
	Join ContactMechanism.PartyContactMechanisms PCM on CD.PartyID = PCM.PartyID
	Left Join ContactMechanism.PostalAddresses PA on CD.PostalAddressContactMechanismID = PA.ContactMechanismID
	Left Join ContactMechanism.EmailAddresses EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
	left join Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
	left join ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
	Join Vehicle.Vehicles V on CD.VIN = V.VIN
	Where	CD.SelectionRequirementID in (@SelectionID_LR24M_UK,@SelectionID_LR24M_CHN,@SelectionID_LR24M_AUS,@SelectionID_LR24M_RUS)
	AND CD.CaseStatusTypeID <> 2

-- set selection id for questionniare Land Rover 1M  ------------------------------------------------				--1.3v
Set @QuestionnaireRequirementID = NULL
Select	@QuestionnaireRequirementID = RequirementIDPartOf
From	requirement.RequirementRollups rr
Where	RequirementIDMadeUpOf in (Select QuestionnaireRequirementID from dbo.BrandMarketQuestionnaireSampleMetadata where SelectionName like '%LR%1M%')

insert into #tmp_1
Select distinct	CD.PartyID,
		CD.CaseID,
		Country,
		'LR' as ManufacturerName,
		CD.VIN,
		CD.ChassisNumber,
		ModelDescription as FullModelDesc,
		RegistrationNumber, 
		Null DeliveryDate,
		NULL as Salutation, 
		NULL as Addressee,
		Title, 
		FirstName,
		LastName, 
		SecondLastName,
		OrganisationName,
		BuildingName, 
		SubStreet, 
		StreetNumber,
		Street, 
		SubLocality, 
		Locality, 
		Town, 
		Region, 
		PostCode,
		WorkLandlineID as telnum,
		LandlineID as telnum2,
		MobileID as telnum3,
		Emailaddress,
		Current_TimeStamp OutputDate,
		SaleType,
		Selection, 
		ModelDerivative,
		' ' as RejectionTypeID,
		' ' as RejectionID,
		DealerName,
		DealerCode,
		DealerPartyID ,   -- v1.5
		RegistrationDate,
		EventDate,
		OwnershipCycle,
		BuildYear as ModelYear,
		GenderID,
		SelectionRequirementID
	From	Meta.CaseDetails CD
	Join ContactMechanism.PartyContactMechanisms PCM on CD.PartyID = PCM.PartyID
	Left Join ContactMechanism.PostalAddresses PA on CD.PostalAddressContactMechanismID = PA.ContactMechanismID
	Left Join ContactMechanism.EmailAddresses EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
	left join Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
	left join ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
	Join Vehicle.Vehicles V on CD.VIN = V.VIN
	Where	CD.SelectionRequirementID in (@SelectionID_LR1M_UK,@SelectionID_LR1M_AUS,@SelectionID_LR1M_RUS,@SelectionID_LR1M_CHN)
	AND CD.CaseStatusTypeID <> 2
	
alter table #tmp_1
alter column telnum3 nvarchar(400)

alter table #tmp_1
alter column telnum nvarchar(400)

alter table #tmp_1
alter column telnum2 nvarchar(400)

update #tmp_1
set telnum3 = tn.contactnumber
from  ContactMechanism.TelephoneNumbers tn 
where tn.ContactMechanismID = #tmp_1.telnum3


update #tmp_1
set telnum = tn.contactnumber
from  ContactMechanism.TelephoneNumbers tn 
where tn.ContactMechanismID = #tmp_1.telnum


update #tmp_1
set telnum2 = tn.contactnumber
from  ContactMechanism.TelephoneNumbers tn 
where tn.ContactMechanismID = #tmp_1.telnum2

update #tmp_1
set Country = dw.market
from dw_jlrcspdealers dw
where (DealerPartyID  = dw.OutletPartyID)		 -- v1.5
and  #tmp_1.country is null
-- v1.5 -- and dw.market in ('Russian Federation','China','UK','Australia', 'France', 'Spain', 'Italy')  -- 1.4


update #tmp_1
set BuildingName = pa.BuildingName,SubStreet = pa.SubStreet,StreetNumber = pa.StreetNumber,Street = pa.Street,
SubLocality = pa.SubLocality,Locality = pa.Locality,Town = pa.Town,Region = pa.Region,PostCode = pa.PostCode
from contactmechanism.postaladdresses pa
join contactmechanism.partycontactmechanisms pcm on pcm.contactmechanismid = pa.contactmechanismid
join event.automotiveeventbasedinterviews aebi on pcm.partyid = aebi.partyid
where #tmp_1.caseid = aebi.caseid
and #tmp_1.Street is null

-----------------------------------------------------------------------------------------------------------------------------------------------
/*Output Formatting*/
-----------------------------------------------------------------------------------------------------------------------------------------------

update #tmp_1
set ownershipcycle = ''
where ownershipcycle is null

update #tmp_1
set OrganisationName = ''
where len(OrganisationName) = 0

update #tmp_1
set Title = ''
where Title is null

update #tmp_1
set FirstName = ''
where firstname is NULL

update #tmp_1
set lastname = ''
where lastname is NULL

update #tmp_1
set secondlastname = ''
where secondlastname is NULL

update #tmp_1
set Street = ''
where Street is NULL

update #tmp_1
set SubLocality = ''
where SubLocality is NULL

update #tmp_1
set Town = ''
where town is NULL

update #tmp_1
set Region = ''
where Region is NULL

update #tmp_1
set PostCode = ''
where PostCode is NULL

update #tmp_1
set emailaddress = ''
where emailaddress is null

update #tmp_1
set telnum2 = ''
where telnum2 is null

update #tmp_1
set telnum3 = ''
where telnum3 is null

update #tmp_1
set ModelDerivative = 'Discovery'
where ModelDerivative = 'Discovery 4'

update #tmp_1
set ModelDerivative = 'Freelander'
where ModelDerivative = 'Freelander 2'

update #tmp_1
set ModelDerivative = 'Range Rover'
where ModelDerivative = 'Range Rover (excl sport)'

update #tmp_1
set ModelDerivative = 'XK'
where ModelDerivative = 'XK/XKR'

update #tmp_1
set modelderivative = 'Defender'
where modelderivative = 'Defender (08/09MY)'


update #tmp_1
set modelderivative = 'Range Rover Sport'
where modelderivative = 'Range Rover Sport (2010MY)'

--update #tmp_4
--set ModelDerivative = 'Range Rover Sport'
--where ModelDerivative = 'Range Rover (excl Sport) (Inc China)'
--and VIN like 'SALS%'
--and country = 'China'

update #tmp_1
set modelderivative = 'Range Rover Sport'
where modelderivative = 'Range Rover Sport (Inc China)'

update #tmp_1
set modelderivative = 'Discovery'
where modelderivative = 'Discovery (0809MY)'


update #tmp_1
set modelderivative = 'Range Rover'
where modelderivative = 'Range Rover (2010MY)'


update #tmp_1
set modelderivative = 'Discovery'
where modelderivative = 'Discovery (2010MY)'


update #tmp_1
set modelderivative = 'Defender'
where modelderivative = 'Defender (2010MY)'

update #tmp_1
set modelderivative = 'Range Rover'
where modelderivative = 'Range Rover (0809MY)'

update #tmp_1
set modelderivative = 'Range Rover'
where modelderivative = 'Range Rover (excl Sport) (Inc China)'

update #tmp_1
set modelderivative = 'Discovery'
where modelderivative = 'Discovery (Inc China)'

update #tmp_1
set modelderivative = 'Range Rover Sport'
where modelderivative = 'Range Rover Sport (0809MY)'

update #tmp_1
set modelderivative = 'Freelander'
where modelderivative = 'Freelander 2 (2010MY)'

update #tmp_1
set modelderivative = 'XF'
where modelderivative like 'XF%'

update #tmp_1
set modelderivative = 'Range Rover'
where vin like 'SALG%'


update #tmp_1
set country = 'United Kingdom'
where country = 'UK'



delete from Enprecis.JaguarDataUK_3M
delete from Enprecis.JaguarDataUK_12M
delete from Enprecis.JaguarDataUK_24M			--1.2v
delete from Enprecis.JaguarDataUK_1M				--1.3v

delete from Enprecis.LandRoverDataUK_3M
delete from Enprecis.LandRoverDataUK_12M
delete from Enprecis.LandRoverDataUK_24M			--1.2v
delete from Enprecis.LandRoverDataUK_1M			--1.3v


--Jaguar
---------1M
insert into Enprecis.JaguarDataUK_1M
select distinct 'RETAILSALETYPE' as 'SalesRecordType',
Country as 'Country',
VIN,
FirstName as 'CustomerFirstName',
LastName as 'CustomerLastName',
StreetNumber+ ' ' + Street as 'CustomerAddressOne',
SubLocality as 'CustomerAddressTwo',
Town as 'CustomerCity',
Region as 'CustomerState',
PostCode as 'CustomerZip',
emailaddress as 'CustomersEmailAddress',
coalesce (telnum,telnum2) as 'CustomerPhoneOne',
telnum3 as 'CustomerPhoneTwo',
ModelDerivative  as 'ModelType',
-- when Country in ( 'United Kingdom')
-- then 'XJ','XK','XF'
-- End 'Model Type'
-- when Country in ( 'China')
-- then 'XF', 'XJ' 
ModelYear as ModelYear,
DealerName,
DealerCode,
csp.subnationalregion as 'SalesRegion',
' ' as 'SalesDistrict',
EventDate as 'SalesDate',
RegistrationDate as 'RDRDate',
' ' as 'ManufacturingDate' ,
' ' as 'TrimLevel',
' ' as 'ExteriorColor',
' ' as 'InteriorColor',
' ' as 'Transmission',
' ' as 'EngineType',
CaseID as 'Caseid',
Title as 'CustomerTitle',
RegistrationNumber as 'RegistrationPlate',
Title as 'Salutation',
SecondLastName as 'SecondSurname',
OwnershipCycle
from #tmp_1 t
left join dbo.DW_JLRCSPDealers csp on t.DealerPartyID  = csp.OutletPartyID		 -- v1.5
join requirement.requirements r on t.selectionrequirementid = r.requirementid
join requirement.requirementrollups rr on r.requirementid = rr.requirementidpartof
where csp.outletfunction = 'Sales'
and not(modelderivative is null)
and r.requirement like '%1M%Jag%'
and csp.manufacturer = 'Jaguar'
and csp.market in ('Australia','UK','Russian Federation','China', 'Italy', 'France', 'Spain') --1.4

---------3M
insert into Enprecis.JaguarDataUK_3M
select distinct 'RETAILSALETYPE' as 'SalesRecordType',
Country as 'Country',
VIN,
FirstName as 'CustomerFirstName',
LastName as 'CustomerLastName',
StreetNumber+ ' ' + Street as 'CustomerAddressOne',
SubLocality as 'CustomerAddressTwo',
Town as 'CustomerCity',
Region as 'CustomerState',
PostCode as 'CustomerZip',
emailaddress as 'CustomersEmailAddress',
coalesce (telnum,telnum2) as 'CustomerPhoneOne',
telnum3 as 'CustomerPhoneTwo',
ModelDerivative  as 'ModelType',
-- when Country in ( 'United Kingdom')
-- then 'XJ','XK','XF'
-- End 'Model Type'
-- when Country in ( 'China')
-- then 'XF', 'XJ' 
ModelYear as ModelYear,
DealerName,
DealerCode,
csp.subnationalregion as 'SalesRegion',
' ' as 'SalesDistrict',
EventDate as 'SalesDate',
RegistrationDate as 'RDRDate',
' ' as 'ManufacturingDate' ,
' ' as 'TrimLevel',
' ' as 'ExteriorColor',
' ' as 'InteriorColor',
' ' as 'Transmission',
' ' as 'EngineType',
CaseID as 'Caseid',
Title as 'CustomerTitle',
RegistrationNumber as 'RegistrationPlate',
Title as 'Salutation',
SecondLastName as 'SecondSurname',
OwnershipCycle
from #tmp_1 t
left join dbo.DW_JLRCSPDealers csp on t.DealerPartyID  = csp.OutletPartyID		 -- v1.5
join requirement.requirements r on t.selectionrequirementid = r.requirementid
join requirement.requirementrollups rr on r.requirementid = rr.requirementidpartof
where csp.outletfunction = 'Sales'
and not(modelderivative is null)
and r.requirement like '%3M%Jag%'
and csp.manufacturer = 'Jaguar'
and csp.market in ('Australia','UK','Russian Federation','China', 'Italy', 'France', 'Spain')  --1.4

---------12M
insert into Enprecis.JaguarDataUK_12M
select distinct 'RETAILSALETYPE' as 'SalesRecordType',
Country as 'Country',
VIN,
FirstName as 'CustomerFirstName',
LastName as 'CustomerLastName',
StreetNumber+ ' ' + Street as 'CustomerAddressOne',
SubLocality as 'CustomerAddressTwo',
Town as 'CustomerCity',
Region as 'CustomerState',
PostCode as 'CustomerZip',
emailaddress as 'CustomersEmailAddress',
coalesce (telnum,telnum2) as 'CustomerPhoneOne',
telnum3 as 'CustomerPhoneTwo',
ModelDerivative  as 'ModelType',
-- when Country in ( 'United kingdom')
-- then 'XJ', 'XK', 'XF'
-- End 'Model Type'
ModelYear as ModelYear,
DealerName,
DealerCode,
csp.subnationalregion as 'SalesRegion',
' ' as 'SalesDistrict',
EventDate as 'SalesDate',
RegistrationDate as 'RDRDate',
' ' as 'ManufacturingDate' ,
' ' as 'TrimLevel',
' ' as 'ExteriorColor',
' ' as 'InteriorColor',
' ' as 'Transmission',
' ' as 'EngineType',
CaseID as 'Caseid',
Title as 'CustomerTitle',
RegistrationNumber as 'RegistrationPlate',
Title as 'Salutation',
SecondLastName as 'SecondSurname',
OwnershipCycle
from #tmp_1 t
left join dbo.DW_JLRCSPDealers csp on t.DealerPartyID  = csp.OutletPartyID		 -- v1.5
join requirement.requirements r on t.selectionrequirementid = r.requirementid
join requirement.requirementrollups rr on r.requirementid = rr.requirementidpartof
where csp.outletfunction = 'Sales'
and not(modelderivative is null)
and r.requirement like '%12M%Jag%'
and csp.manufacturer = 'Jaguar'
and csp.subnationalregion <> 'Inactive'
and csp.market in ('Australia','UK','Russian Federation','China')

---------24M													--1.2v
insert into Enprecis.JaguarDataUK_24M
select distinct 'RETAILSALETYPE' as 'SalesRecordType',
Country as 'Country',
VIN,
FirstName as 'CustomerFirstName',
LastName as 'CustomerLastName',
StreetNumber+ ' ' + Street as 'CustomerAddressOne',
SubLocality as 'CustomerAddressTwo',
Town as 'CustomerCity',
Region as 'CustomerState',
PostCode as 'CustomerZip',
emailaddress as 'CustomersEmailAddress',
coalesce (telnum,telnum2) as 'CustomerPhoneOne',
telnum3 as 'CustomerPhoneTwo',
ModelDerivative  as 'ModelType',
-- when Country in ( 'United kingdom')
-- then 'XJ', 'XK', 'XF'
-- End 'Model Type'
ModelYear as ModelYear,
DealerName,
DealerCode,
csp.subnationalregion as 'SalesRegion',
' ' as 'SalesDistrict',
EventDate as 'SalesDate',
RegistrationDate as 'RDRDate',
' ' as 'ManufacturingDate' ,
' ' as 'TrimLevel',
' ' as 'ExteriorColor',
' ' as 'InteriorColor',
' ' as 'Transmission',
' ' as 'EngineType',
CaseID as 'Caseid',
Title as 'CustomerTitle',
RegistrationNumber as 'RegistrationPlate',
Title as 'Salutation',
SecondLastName as 'SecondSurname',
OwnershipCycle
from #tmp_1 t
left join dbo.DW_JLRCSPDealers csp on t.DealerPartyID  = csp.OutletPartyID		 -- v1.5
join requirement.requirements r on t.selectionrequirementid = r.requirementid
join requirement.requirementrollups rr on r.requirementid = rr.requirementidpartof
where csp.outletfunction = 'Sales'
and not(modelderivative is null)
and r.requirement like '%24M%Jag%'
and csp.manufacturer = 'Jaguar'
and csp.subnationalregion <> 'Inactive'
and csp.market in ('Australia','UK','Russian Federation','China')

--Land Rover
---------3M													
insert into Enprecis.LandRoverDataUK_3M
select distinct 'RETAILSALETYPE' as 'SalesRecordType',
Country as 'Country',
VIN,
FirstName as 'CustomerFirstName',
LastName as 'CustomerLastName',
StreetNumber+ ' ' + Street as 'CustomerAddressOne',
SubLocality as 'CustomerAddressTwo',
Town as 'CustomerCity',
Region as 'CustomerState',
PostCode as 'CustomerZip',
emailaddress as 'CustomersEmailAddress',
coalesce (telnum,telnum2) as 'CustomerPhoneOne',
telnum3 as 'CustomerPhoneTwo',
ModelDerivative as 'ModelType',
ModelYear as ModelYear,
DealerName,
DealerCode,
csp.subnationalregion as 'SalesRegion',
' ' as 'SalesDistrict',
EventDate as 'SalesDate',
RegistrationDate as 'RDRDate',
' ' as 'ManufacturingDate' ,
' ' as 'TrimLevel',
' ' as 'ExteriorColor',
' ' as 'InteriorColor',
' ' as 'Transmission',
' ' as 'EngineType',
CaseID as 'Caseid',
Title as 'CustomerTitle',
RegistrationNumber as 'RegistrationPlate',
Title as 'Salutation',
SecondLastName as 'SecondSurname',
OwnershipCycle
from #tmp_1 t
left join dbo.DW_JLRCSPDealers csp on t.DealerPartyID  = csp.OutletPartyID		 -- v1.5
join requirement.requirements r on t.selectionrequirementid = r.requirementid
join requirement.requirementrollups rr on r.requirementid = rr.requirementidpartof
where csp.outletfunction = 'Sales'
and not(modelderivative is null)
and r.requirement like '%3M%LR%'
and csp.manufacturer = 'Land Rover'
and csp.subnationalregion <> 'Inactive'
and csp.market in ('Australia','UK','Russian Federation','China', 'Italy', 'France', 'Spain')  -- 1.4

---------12M		
insert into Enprecis.LandRoverDataUK_12M
select distinct 'RETAILSALETYPE' as 'SalesRecordType',
Country as 'Country',
VIN,
FirstName as 'CustomerFirstName',
LastName as 'CustomerLastName',
StreetNumber+ ' ' + Street as 'CustomerAddressOne',
SubLocality as 'CustomerAddressTwo',
Town as 'CustomerCity',
Region as 'CustomerState',
PostCode as 'CustomerZip',
emailaddress as 'CustomersEmailAddress',
coalesce (telnum,telnum2) as 'CustomerPhoneOne',
telnum3 as 'CustomerPhoneTwo',
ModelDerivative as 'ModelType',
-- when Country in ( 'United kingdom')
-- then  'Freelander', 'Discovery', 'Range Rover Sport','Range Rover','Defender'
-- when Country in ( 'australia')
-- then 'Discovery', 'Freelander', 'Range Rover Sport'
-- End 'Model Type'
ModelYear as ModelYear,
DealerName,
DealerCode,
csp.subnationalregion as 'SalesRegion',
' ' as 'SalesDistrict',
EventDate as 'SalesDate',
RegistrationDate as 'RDRDate',
' ' as 'ManufacturingDate' ,
' ' as 'TrimLevel',
' ' as 'ExteriorColor',
' ' as 'InteriorColor',
' ' as 'Transmission',
' ' as 'EngineType',
CaseID as 'Caseid',
Title as 'CustomerTitle',
RegistrationNumber as 'RegistrationPlate',
Title as 'Salutation',
SecondLastName as 'SecondSurname',
OwnershipCycle
from #tmp_1 t
left join dbo.DW_JLRCSPDealers csp on t.DealerPartyID  = csp.OutletPartyID		 -- v1.5
join requirement.requirements r on t.selectionrequirementid = r.requirementid
join requirement.requirementrollups rr on r.requirementid = rr.requirementidpartof
where csp.outletfunction = 'Sales'
and (organisationName = '' )
and not(modelderivative is null)
and r.requirement like '%12M%LR%'
and csp.manufacturer = 'Land Rover'
and csp.subnationalregion <> 'Inactive'
and csp.market in ('Australia','UK','Russian Federation','China')

---------24M														--1.2v	
INSERT INTO Enprecis.LandRoverDataUK_24M
SELECT DISTINCT 'RETAILSALETYPE' as 'SalesRecordType',
Country as 'Country',
VIN,
FirstName as 'CustomerFirstName',
LastName as 'CustomerLastName',
StreetNumber+ ' ' + Street as 'CustomerAddressOne',
SubLocality as 'CustomerAddressTwo',
Town as 'CustomerCity',
Region as 'CustomerState',
PostCode as 'CustomerZip',
emailaddress as 'CustomersEmailAddress',
coalesce (telnum,telnum2) as 'CustomerPhoneOne',
telnum3 as 'CustomerPhoneTwo',
ModelDerivative as 'ModelType',
ModelYear as ModelYear,
DealerName,
DealerCode,
csp.subnationalregion as 'SalesRegion',
' ' as 'SalesDistrict',
EventDate as 'SalesDate',
RegistrationDate as 'RDRDate',
' ' as 'ManufacturingDate' ,
' ' as 'TrimLevel',
' ' as 'ExteriorColor',
' ' as 'InteriorColor',
' ' as 'Transmission',
' ' as 'EngineType',
CaseID as 'Caseid',
Title as 'CustomerTitle',
RegistrationNumber as 'RegistrationPlate',
Title as 'Salutation',
SecondLastName as 'SecondSurname',
OwnershipCycle
from #tmp_1 t
left join dbo.DW_JLRCSPDealers csp on t.DealerPartyID  = csp.OutletPartyID		 -- v1.5
join requirement.Requirements r on t.selectionrequirementid = r.requirementid
join requirement.requirementrollups rr on r.requirementid = rr.requirementidpartof
where csp.outletfunction = 'Sales'
and (OrganisationName = '' )
and not(modelderivative is null)
and r.requirement like '%24M%LR%'
and csp.manufacturer = 'Land Rover'
and csp.subnationalregion <> 'Inactive'
and csp.market in ('Australia','UK','Russian Federation','China')

---------1M														--1.3v	
INSERT INTO Enprecis.LandRoverDataUK_1M
SELECT DISTINCT 'RETAILSALETYPE' as 'SalesRecordType',
Country as 'Country',
VIN,
FirstName as 'CustomerFirstName',
LastName as 'CustomerLastName',
StreetNumber+ ' ' + Street as 'CustomerAddressOne',
SubLocality as 'CustomerAddressTwo',
Town as 'CustomerCity',
Region as 'CustomerState',
PostCode as 'CustomerZip',
emailaddress as 'CustomersEmailAddress',
coalesce (telnum,telnum2) as 'CustomerPhoneOne',
telnum3 as 'CustomerPhoneTwo',
ModelDerivative as 'ModelType',
ModelYear as ModelYear,
DealerName,
DealerCode,
csp.subnationalregion as 'SalesRegion',
' ' as 'SalesDistrict',
EventDate as 'SalesDate',
RegistrationDate as 'RDRDate',
' ' as 'ManufacturingDate' ,
' ' as 'TrimLevel',
' ' as 'ExteriorColor',
' ' as 'InteriorColor',
' ' as 'Transmission',
' ' as 'EngineType',
CaseID as 'Caseid',
Title as 'CustomerTitle',
RegistrationNumber as 'RegistrationPlate',
Title as 'Salutation',
SecondLastName as 'SecondSurname',
OwnershipCycle
from #tmp_1 t
left join dbo.DW_JLRCSPDealers csp on t.DealerPartyID  = csp.OutletPartyID		 -- v1.5
join requirement.Requirements r on t.selectionrequirementid = r.requirementid
join requirement.requirementrollups rr on r.requirementid = rr.requirementidpartof
where csp.outletfunction = 'Sales'
and (OrganisationName = '' )
and not(modelderivative is null)
and r.requirement like '%1M%LR%'
and csp.manufacturer = 'Land Rover'
and csp.subnationalregion <> 'Inactive'
and csp.market in ('Australia','UK','Russian Federation','China')
and (ModelDerivative like '%evoque%' or vin like 'salg%' or vin like 'salw%')

-------------------------------------------------------------------
/*JLR Selection details/rules*/
-------------------------------------------------------------------
--LandRover 1MIS LIMITATIONS


--JAGUAR 3MIS LIMITATIONS
delete from Enprecis.JaguarDataUK_3M
where Country not in ('united kingdom','china', 'Italy', 'France', 'Spain')  --1.4

delete from Enprecis.JaguarDataUK_3M
where Country = 'united kingdom'
and modeltype not in ('f-type', 'xj','xk','xf')

delete from Enprecis.JaguarDataUK_3M
where Country = 'china'
and modeltype not in ('f-type', 'xj','xf')

--LandRover 3MIS LIMITATIONS
delete from Enprecis.LandRoverDataUK_3M
where Country = 'australia'
and modeltype not in ('Discovery', 'Freelander', 'Range Rover Sport','Range Rover Evoque')

delete from Enprecis.LandRoverDataUK_3M
where Country = 'Russian Federation'
and modeltype not in ('Range Rover', 'Range Rover Sport', 'Discovery','Freelander','Range Rover Evoque')

delete from Enprecis.LandRoverDataUK_3M
where Country = 'china'
and modeltype not in ('Range Rover', 'Range Rover Sport', 'Discovery', 'Freelander','Range Rover Evoque')
--------------------------------------------------------
--JAGUAR 12MIS LIMITATIONS
delete from Enprecis.JaguarDataUK_12M
where Country not in ('united kingdom')

--LandRover 12MIS LIMITATIONS
delete from Enprecis.LandRoverDataUK_12M
where Country not in ('united kingdom','australia')

delete from Enprecis.LandRoverDataUK_12M
where Country = 'australia'
and modeltype not in ('Discovery', 'Freelander', 'Range Rover Sport','Range Rover Evoque')
--------------------------------------------------------
--JAGUAR 24MIS LIMITATIONS
delete from Enprecis.JaguarDataUK_24M
where Country not in ('united kingdom')

--LandRover 24MIS LIMITATIONS
delete from Enprecis.LandRoverDataUK_24M
where Country not in ('united kingdom','australia')

delete from Enprecis.LandRoverDataUK_24M
where Country = 'australia'
and modeltype not in ('Discovery', 'Freelander', 'Range Rover Sport','Range Rover Evoque')

-------------------------------------------------------------------------------------
--JAGUAR 1MIS UPDATES
update Enprecis.JaguarDataUK_1M
set salutation = 'Dear' + ' ' + customertitle + ' ' + CustomerLastName
where Country in ('united kingdom','australia')
and not(len(customertitle) < 1)

update Enprecis.JaguarDataUK_1M
set salutation = 'Dear Sirs'
where Country in ('united kingdom','australia')
and (len(customertitle) < 1)


--JAGUAR 3MIS UPDATES
update Enprecis.JaguarDataUK_3M
set salutation = 'Dear' + ' ' + customertitle + ' ' + CustomerLastName
where Country in ('united kingdom','australia')
and not(len(customertitle) < 1)

update Enprecis.JaguarDataUK_3M
set salutation = 'Dear Sirs'
where Country in ('united kingdom','australia')
and (len(customertitle) < 1)

--JAGUAR 12MIS UPDATES
update Enprecis.JaguarDataUK_12M
set salutation = 'Dear' + ' ' + customertitle + ' ' + CustomerLastName
where Country in ('united kingdom','australia')
and not(len(customertitle) < 1)

update Enprecis.JaguarDataUK_12M
set salutation = 'Dear Sirs'
where Country in ('united kingdom','australia')
and (len(customertitle) < 1)

--JAGUAR 24MIS UPDATES
update Enprecis.JaguarDataUK_24M
set salutation = 'Dear' + ' ' + customertitle + ' ' + CustomerLastName
where Country in ('united kingdom','australia')
and not(len(customertitle) < 1)

update Enprecis.JaguarDataUK_24M
set salutation = 'Dear Sirs'
where Country in ('united kingdom','australia')
and (len(customertitle) < 1)

--------------------------------------------------------
--LandRover 3MIS UPDATES
update Enprecis.LandRoverDataUK_3M
set salutation = 'Dear' + ' ' + customertitle + ' ' + CustomerLastName
where Country in ('united kingdom','australia')
and not(len(customertitle) < 1)

update Enprecis.LandRoverDataUK_3M
set salutation = 'Dear Sirs'
where Country in ('united kingdom','australia')
and (len(customertitle) < 1)

--LandRover 12MIS UPDATES
update Enprecis.LandRoverDataUK_12M
set salutation = 'Dear' + ' ' + customertitle + ' ' + CustomerLastName
where Country in ('united kingdom','australia')
and not(len(customertitle) < 1)

update Enprecis.LandRoverDataUK_12M
set salutation = 'Dear Sirs'
where Country in ('united kingdom','australia')
and (len(customertitle) < 1)

--LandRover 24MIS UPDATES
update Enprecis.LandRoverDataUK_24M
set salutation = 'Dear' + ' ' + customertitle + ' ' + CustomerLastName
where Country in ('united kingdom','australia')
and not(len(customertitle) < 1)

update Enprecis.LandRoverDataUK_24M
set salutation = 'Dear Sirs'
where Country in ('united kingdom','australia')
and (len(customertitle) < 1)

--LandRover 1MIS UPDATES
update Enprecis.LandRoverDataUK_1M
set salutation = 'Dear' + ' ' + customertitle + ' ' + CustomerLastName
where Country in ('united kingdom','australia')
and not(len(customertitle) < 1)

update Enprecis.LandRoverDataUK_1M
set salutation = 'Dear Sirs'
where Country in ('united kingdom','australia')
and (len(customertitle) < 1)

-------------------------------------------------------------------------------------
/*MODEL TYPE UPDATES TO OUTPUT*/
update Enprecis.LandRoverDataUK_12M
set modeltype = 'Freelander'
where modeltype = 'Freelander 2 (2010MY)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Discovery'
where modeltype = 'Discovery (2010MY)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Range Rover'
where modeltype = 'Range Rover (2010MY)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Range Rover Sport'
where modeltype = 'Range Rover Sport (2010MY)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Discovery'
where modeltype = 'Discovery (Inc China)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Defender'
where modeltype = 'Defender (08/09MY)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Range Rover Sport'
where modeltype = 'Range Rover Sport (Inc China)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Defender'
where modeltype = 'Defender (2010MY)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Freelander'
where modeltype = 'Freelander 2 (0809MY)'

update Enprecis.LandRoverDataUK_12M
set modeltype = 'Range Rover'
where modeltype = 'Range Rover (excl Sport) (Inc China)'

---------------------------------------------------
update Enprecis.LandRoverDataUK_3M
set modeltype = 'Freelander'
where modeltype = 'Freelander 2 (2010MY)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Discovery'
where modeltype = 'Discovery (2010MY)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Range Rover'
where modeltype = 'Range Rover (2010MY)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Range Rover Sport'
where modeltype = 'Range Rover Sport (2010MY)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Discovery'
where modeltype = 'Discovery (Inc China)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Defender'
where modeltype = 'Defender (08/09MY)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Range Rover Sport'
where modeltype = 'Range Rover Sport (Inc China)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Defender'
where modeltype = 'Defender (08/09MY)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Range Rover'
where modeltype = 'Range Rover (excl Sport) (Inc China)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Freelander'
where modeltype = 'Freelander 2 (0809MY)'

update Enprecis.LandRoverDataUK_3M
set modeltype = 'Defender'
where modeltype = 'Defender (2010MY)'
---------------------------------------------------

--RANGE ROVER SPORT (0809MY) OR OTHER (0809MY)MODEL NEEDS TO BE ADDED IF THE 24MIS GETS SET HERE AS IT FALLS INTO THE RANGE
--	SELECT GETDATE()-690
	
--Freelander
update Enprecis.LandRoverDataUK_24M
set modeltype = 'Freelander'
where modeltype = 'Freelander 2 (2010MY)'

update Enprecis.LandRoverDataUK_24M
set modeltype = 'Freelander'
where modeltype = 'Freelander 2 (0809MY)'

--Discovery
update Enprecis.LandRoverDataUK_24M
set modeltype = 'Discovery'
where modeltype = 'Discovery (2010MY)'

update Enprecis.LandRoverDataUK_24M
set modeltype = 'Discovery'
where modeltype = 'Discovery (Inc China)'

update Enprecis.LandRoverDataUK_24M
set modeltype = 'Discovery'
where modeltype = 'Discovery (0809MY)'

--Range Rover
update Enprecis.LandRoverDataUK_24M
set modeltype = 'Range Rover'
where modeltype = 'Range Rover (2010MY)'

update Enprecis.LandRoverDataUK_24M
set modeltype = 'Range Rover'
where modeltype = 'Range Rover (excl Sport) (Inc China)'

--Range Rover Sport
update Enprecis.LandRoverDataUK_24M
set modeltype = 'Range Rover Sport'
where modeltype = 'Range Rover Sport (2010MY)'

update Enprecis.LandRoverDataUK_24M
set modeltype = 'Range Rover Sport'
where modeltype = 'Range Rover Sport (Inc China)'

--Defender
update Enprecis.LandRoverDataUK_24M
set modeltype = 'Defender'
where modeltype = 'Defender (08/09MY)'

update Enprecis.LandRoverDataUK_24M
set modeltype = 'Defender'
where modeltype = 'Defender (2010MY)'


--China RR sport

update Enprecis.LandRoverDataUK_24M
set ModelType = 'Range Rover Sport'
where VIN like 'SALS%'
and Country = 'China'

update Enprecis.LandRoverDataUK_3M
set ModelType = 'Range Rover Sport'
where VIN like 'SALS%'
and Country = 'China'

update Enprecis.LandRoverDataUK_1M
set ModelType = 'Range Rover Sport'
where VIN like 'SALS%'
and Country = 'China'

update Enprecis.LandRoverDataUK_12M
set ModelType = 'Range Rover Sport'
where VIN like 'SALS%'
and Country = 'China'

END

