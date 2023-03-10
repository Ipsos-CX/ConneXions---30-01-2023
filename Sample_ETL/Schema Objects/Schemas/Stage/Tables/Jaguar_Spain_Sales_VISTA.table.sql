CREATE TABLE [Stage].[Jaguar_Spain_Sales_VISTA](
		[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[PhysicalRowID] [int] NULL,
	[Partner Unique Id] [dbo].[LoadText] NULL,
	[Common Order Number] [dbo].[LoadText] NULL,
	[VIN] [dbo].[LoadText] NULL,
	[Customer Id] [dbo].[LoadText] NULL,
	[Cust Type] [dbo].[LoadText] NULL,
	[Payment Type] [dbo].[LoadText] NULL,
	[Type of Sale] [dbo].[LoadText] NULL,
	[Handover Date] [dbo].[LoadText] NULL,
	[Salesman Code Dropdown] [dbo].[LoadText] NULL,
	[Contract Relationship] [dbo].[LoadText] NULL,
	[Customers] [dbo].[LoadText] NULL,
	[Last Name] [dbo].[LoadText] NULL,
	[Forename(s)] [dbo].[LoadText] NULL,
	[Gender] [dbo].[LoadText] NULL,
	[Academic Title] [dbo].[LoadText] NULL,
	[Date of Birth] [dbo].[LoadText] NULL,
	[Non Academic Title] [dbo].[LoadText] NULL,
	[E-mail Address] [dbo].[LoadText] NULL,
	[Mobile Telephone] [dbo].[LoadText] NULL,
	[Home Telephone] [dbo].[LoadText] NULL,
	[Work Telephone] [dbo].[LoadText] NULL,
	[Address Line2] [dbo].[LoadText] NULL,
	[Address 3] [dbo].[LoadText] NULL,
	[Address 4] [dbo].[LoadText] NULL,
	[Post Code] [dbo].[LoadText] NULL,
	[Town] [dbo].[LoadText] NULL,
	[Company Name] [dbo].[LoadText] NULL,
	[E-mail marketing opt-in] [dbo].[LoadText] NULL,
	[Telephone Number] [dbo].[LoadText] NULL,
	[Mobile phone marketing opt-in] [dbo].[LoadText] NULL,
	[Model Description] [dbo].[LoadText] NULL,
	[Derivative Description] [dbo].[LoadText] NULL,
	[Model Year Description] [dbo].[LoadText] NULL,
	[Exterior Colour Long Description] [dbo].[LoadText] NULL,
	[Interior Trim Long Description] [dbo].[LoadText] NULL,
	[Registration Number] [dbo].[LoadText] NULL,
	[Registration Date] [dbo].[LoadText] NULL,
	[Salesman Code] [dbo].[LoadText] NULL,
	[Salesman First Name] [dbo].[LoadText] NULL,
	[Salesman Surname] [dbo].[LoadText] NULL,
	[Additional Surname] [dbo].[LoadText] NULL,
	[Street name and type] [dbo].[LoadText] NULL,
	[State-County] [dbo].[LoadText] NULL,
	[Initial] [dbo].[LoadText] NULL,
	[Preferred Language] [dbo].[LoadText] NULL,
	[consent for further contact] [dbo].[LoadText] NULL,
	[Mail marketing opt-in] [dbo].[LoadText] NULL,
	[Post Code 2] [dbo].[LoadText] NULL,
	[County] [dbo].[LoadText] NULL,
	[Title] [dbo].[LoadText] NULL,
	[Work Telephone 2] [dbo].[LoadText] NULL,
	[Country] [dbo].[LoadText] NULL,
	[State] [dbo].[LoadText] NULL,
	[ConvertedHandoverDate] [datetime2](7) NULL,
	[ConvertedRegistrationDate] [datetime2](7) NULL,
	[ConvertedDateOfBirth] [datetime2](7) NULL,
	[PreferredLanguageId] [dbo].[LanguageID] NULL,
	[CountryID] [dbo].[CountryID] NULL
	)