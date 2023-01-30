CREATE TABLE ContactMechanism.BlacklistTypes (
    BlacklistTypeID   dbo.BlacklistTypeID  IDENTITY (1, 1) NOT NULL,
    BlacklistType				NVARCHAR(150)	NOT NULL,
    PreventsSelection			BIT				NOT NULL,
    AFRLFilter					BIT				NOT NULL	DEFAULT (0),
	EmailExclusionCategoryID	dbo.ExclusionCategoryID NULL				-- 09-12-2019 - BUG 16810
);
