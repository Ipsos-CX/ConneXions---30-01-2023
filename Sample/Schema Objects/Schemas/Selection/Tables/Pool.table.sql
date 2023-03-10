CREATE TABLE [Selection].[Pool](
	[EventID] [dbo].[EventID] NULL,
	[VehicleID] [dbo].[VehicleID] NULL,
	[VehicleRoleTypeID] [dbo].[RoleTypeID] NULL,
	[VIN] [dbo].[VIN] NULL,
	[EventCategory] VARCHAR(50) NULL,					-- BUG 15056 --TASK 877
	[EventCategoryID] [dbo].[EventCategoryID] NULL,
	[EventType] [nvarchar](200) NULL,
	[EventTypeID] [dbo].[EventTypeID] NULL,
	[EventDate] [datetime2](7) NULL,
	[ManufacturerPartyID] [dbo].[PartyID] NULL,
	[ModelID] [dbo].[ModelID] NULL,
	[PartyID] [dbo].[PartyID] NULL,
	[RegistrationNumber] [dbo].[RegistrationNumber] NULL,
	[RegistrationDate] [datetime2](7) NULL,
	[OwnershipCycle] [dbo].[OwnershipCycle] NULL,
	[DealerPartyID] [dbo].[PartyID] NULL,
	[DealerCode] [dbo].[DealerCode] NULL,
	[OrganisationPartyID] [dbo].[PartyID] NULL,
	[CountryID] [dbo].[CountryID] NULL,
	[PostalContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[Street] [dbo].[AddressText] NULL,
	[Postcode] [dbo].[Postcode] NULL,
	[EmailContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[PhoneContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[LandlineContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[MobileContactMechanismID] [dbo].[ContactMechanismID] NULL
) ON [PRIMARY]