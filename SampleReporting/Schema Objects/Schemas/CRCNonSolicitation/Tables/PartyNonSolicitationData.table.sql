CREATE TABLE [CRCNonSolicitation].[PartyNonSolicitationData]
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
	,PostalContactMechanismID dbo.ContactMechanismID NULL
	,BuildingName dbo.AddressText NULL
	,SubStreet dbo.AddressText NULL
	,Street dbo.AddressText NULL
	,SubLocality dbo.AddressText NULL
	,Locality dbo.AddressText NULL
	,Town dbo.AddressText NULL
	,Region dbo.AddressText NULL
	,PostCode dbo.Postcode NULL
	,Country dbo.Country NULL
	,EmailContactMechanismID dbo.ContactMechanismID NULL
	,Email dbo.EmailAddress NULL
)
