CREATE PROCEDURE [SelectionOutput].[uspGetSelectionOutput_CATICLP]

		@Questionnaire VARCHAR(200)

AS

/*
	Purpose:	Get CATI Output
	
	Version			Date				Developer			Comment
	1.0				2017-03-06			Eddie Thomas		Created
	1.1				2017-04-19			Chris Ledger		BUG 13378 - Add EmployeeName
	1.2				2018-09-26			Eddie Thomas		BUG 14820 - Lost Leads -  Global loader change
	1.3				2019-09-25			Ben King			BUG 15569 - Lost Leads - Lost Leads transition - survey links
	1.4				2019-10-15			Chris Ross			BUG 16654 - Update default CATI survey link to IPSOS URL
	1.6				2019-10-25			Eddie Thomas		BUG 16667 - Add HotTopicCodes field and PHEV flags
	1.7				2019-10-31			Chris Ledger		BUG 15490 - Add PreOwned LostLeads
	1.8				2019-11-13			Chris Ledger		BUG 15576 - Add Canada to LostLeads Survey URL
	1.9				2020-03-13			Chris Ledger		BUG 16891 - Add ServiceEventType
*/

SELECT     DISTINCT O.Password, O.ID, O.FullModel, O.Model, O.sType, O.CarReg, O.Title, O.Initial, O.Surname, O.Fullname, 
					O.DearName, O.CoName, O.Add1, O.Add2, O.Add3, O.Add4, O.Add5, O.Add6, O.Add7, O.Add8, O.Add9, O.CTRY, 
					O.EmailAddress, O.Dealer, O.sno, O.ccode, O.modelcode, O.lang, O.manuf, O.gender, O.qver, O.blank, 
					O.etype, O.reminder, O.week, O.test, O.SampleFlag, O.SalesServiceFile, O.ITYPE, O.Expired,O.VIN, 
					replace(convert(varchar(10), O.EventDate, 102), '.', '-') AS EventDate, 
					O.DealerCode, O.Telephone, O.WorkTel, O.MobilePhone,
					O.ManufacturerDealerCode, O.ModelYear , O.CustomerIdentifier, O.OwnershipCycle  , O.OutletPartyID,
					O.PartyID, O.GDDDealerCode, O.ReportingDealerPartyID, O.VariantID, O.ModelVariant, 
					CASE 
						WHEN CL.Questionnaire IN ('LostLeads','PreOwned LostLeads') AND CL.Market IN ('GBR','IND')			-- V1.7
							THEN 'https://feedback.tell-jlr.com/S19022329/' + RTRIM(O.ID) +'/' + RTRIM(O.Password) +'/T'
						WHEN CL.Questionnaire IN ('LostLeads','PreOwned LostLeads') AND CL.Market IN ('USA','CAN')			-- V1.7, V1.8
							THEN 'https://feedback.tell-jlr.com/S19022330/' + RTRIM(O.ID) +'/' + RTRIM(O.Password) +'/T'
						ELSE 'https://feedback.tell-jlr.com/T/' + RTRIM(O.ID) +'/' + RTRIM(O.Password)				-- v1.4
					END AS SurveyURL, --V1.3
					O.CATIType,  
					Convert(varchar,Getdate(),103) AS FileDate,
					O.Queue,
					O.AssignedMode,
					O.RequiresManualDial,
					O.CallRecordingsCount,
					O.TimeZone,
					O.CallOutcome,
					O.PhoneNumber,
					O.PhoneSource,
					O.Language,
					O.ExpirationTime,
					O.HomePhoneNumber,
					O.WorkPhoneNumber,
					O.MobilePhoneNumber,
					C.EmployeeName,
					ISNULL(VEH.SVOTypeID,0) AS SVOvehicle,
					VEH.FOBCode,
					O.JLREventType,						--v1.2
					O.DateOfLeadCreation,				--v1.2
					O.CompleteSuppressionJLR,			--v1.2		
					O.CompleteSuppressionRetailer,		--v1.2	
					O.PermissionToEmailJLR,				--v1.2			
					O.PermissionToEmailRetailer,		--v1.2	
					O.PermissionToPhoneJLR,				--v1.2			
					O.PermissionToPhoneRetailer,		--v1.2	
					O.PermissionToPostJLR,				--v1.2			
					O.PermissionToPostRetailer,			--v1.2		
					O.PermissionToSMSJLR,				--v1.2			
					O.PermissionToSMSRetailer,			--v1.2		
					O.PermissionToSocialMediaJLR,		--v1.2	
					O.PermissionToSocialMediaRetailer,	--v1.2
					O.DateOfLastContact,				--v1.5
					O.HotTopicCodes,					--v1.6
					O.ServiceEventType					-- V1.9

FROM				SelectionOutput.OnlineOutput AS O 
INNER JOIN			SelectionOutput.CATI C ON		C.CaseID = O.ID AND 
													C.PartyID = O.PartyID

--FILTER OUT RECORDS WHERE OUTPUT LANGUAGE INVALID
INNER JOIN SelectionOutput.CATIAvailableLanguages CL ON	O.sType = CL.Brand AND
														O.Market = CL.Market AND
														O.lang =  CL.LanguageID
														
INNER JOIN Vehicle.Vehicles VEH			ON O.VIN = VEH.VIN
WHERE CL.Questionnaire = @Questionnaire