﻿CREATE TABLE Stage.FIMSBlackListEmail
				(
					AuditID dbo.AuditID NULL,
					AuditItemID dbo.AuditItemID NULL,
					PhysicalRowID int NULL,
					Email nvarchar(255) NULL,
					Operator [varchar](50) NULL,
					BlacklistTypeID tinyint NULL,
					FromDate [datetime2](7) NULL,
					ContactMechanismID [dbo].[ContactMechanismID] NULL,
					ContactMechanismTypeID [dbo].[ContactMechanismTypeID] NULL,
					BlacklistStringID int NULL,
					AlreadyExists int NULL 	
				)
