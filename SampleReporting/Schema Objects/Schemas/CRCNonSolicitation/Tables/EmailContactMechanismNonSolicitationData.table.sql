CREATE TABLE [CRCNonSolicitation].[EmailContactMechanismNonSolicitationData]
(
	 PartyID dbo.PartyID
	,NonSolicitationText NVARCHAR(50)
	,VehicleID dbo.VehicleID NULL
	,VIN dbo.VIN NULL
	,Title dbo.Title NULL
	,FirstName dbo.NameDetail NULL
	,MiddleName dbo.NameDetail NULL
	,LastName dbo.NameDetail NULL
	,SecondLastName dbo.NameDetail NULL
	,OrganisationName dbo.OrganisationName NULL
	,CurrentPostalContactMechanismID dbo.ContactMechanismID NULL
	,CurrentBuildingName dbo.AddressText NULL
	,CurrentSubStreet dbo.AddressText NULL
	,CurrentStreet dbo.AddressText NULL
	,CurrentSubLocality dbo.AddressText NULL
	,CurrentLocality dbo.AddressText NULL
	,CurrentTown dbo.AddressText NULL
	,CurrentRegion dbo.AddressText NULL
	,CurrentPostCode dbo.Postcode NULL
	,CurrentCountry dbo.Country NULL
	,CurrentEmailContactMechanismID dbo.ContactMechanismID NULL
	,CurrentEmail dbo.EmailAddress NULL
	,NonSolicitedEmailContactMechanismID dbo.ContactMechanismID NULL
	,NonSolicitedEmail dbo.EmailAddress NULL
)
