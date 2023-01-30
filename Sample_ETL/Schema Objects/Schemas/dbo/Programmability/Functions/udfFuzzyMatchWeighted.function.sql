
/*
Purpose:	Pass in two string parameters. Returns a rating value 0-100 that indicates how close a match the strings are.
		Rating		Comment
		NULL		There are no strings to compare i.e. NULL V's Empty String OR NULL V's NULL OR Empty String V's Empty String
		0		There is one string to compare i.e. NULL V's 'Not empty String'
				There are two strings to compare but they are completely different
		1-100		Confidence rating of how similar the strings are
Version		Developer		Date			Comment
1.0		Martin Riverol		07/08/2003		Created
1.1		Martin Riverol		06/10/2003		Added logic to deal with null values and empty strings appearing as part of a comparison.
1.2		Chris Ledger		23/02/2018		BUG 14507: Add specific logic to deal with French companies (S.P.R.L)
1.3		Chris Ledger		09/01/2020		Change RETURNS value to DECIMAL(18) to match UAT/LIVE value
*/

CREATE FUNCTION dbo.udfFuzzyMatchWeighted (@s1 NVARCHAR(150), @s2 NVARCHAR(150))
RETURNS DECIMAL(18) AS  
BEGIN 

declare @strShortest nvarchar(150)
declare @strLongest nvarchar(150)
declare @StrMaskLongest nvarchar(150)
declare @strComparison nvarchar(150)
declare @strTemp nvarchar(150)
declare @intLenShortest smallint
declare @intLenLongest smallint
declare @intMatchPos smallint
declare @intMatchPos2 smallint
declare @intTemp smallint
declare @1CharScore smallint
declare @2CharScore smallint
declare @3CharScore smallint
declare @lenLongString smallint
declare @lenLongString2 smallint
declare @iCounter smallint
declare @1CharMaxScore decimal
declare @2CharMaxScore decimal
declare @3CharMaxScore decimal

--trim input parameters and standardise
set @s1 = upper(replace(@s1, ' ', ''))
set @s2 = upper(replace(@s2, ' ', ''))

-- V1.2 Remove dots in S.P.R.L 
set @s1 = upper(replace(@s1, 'S.P.R.L', 'SPRL'))
set @s2 = upper(replace(@s2, 'S.P.R.L', 'SPRL'))

--Initialize score variables
set @1CharScore = 0
set @2CharScore = 0
set @3CharScore = 0


if len(@s1) > len(@s2)

	begin
		set @strShortest = @s2
		set @intLenShortest = Len(@s2)
		set @strLongest = @s1
		set @intLenLongest = Len(@s1)
	end	

else if Len(@s1) < len(@s2)

	begin
		set @StrShortest = @s1
		set @intLenShortest = Len(@s1)
		set @strLongest = @s2
		set @intLenLongest = Len(@s2)
	end	

else 

	if checksum(@s1) > checksum(@s2)
		
		begin
			set @StrShortest = @s1
			set @intLenShortest = Len(@s1)
			set @strLongest = @s2
			set @intLenLongest = Len(@s2)
		end

	else
		
		begin
			set @StrShortest = @s2
			set @intLenShortest = Len(@s2)
			set @strLongest = @s1
			set @intLenLongest = Len(@s1)
		end
	


--Assign input strings and lengths to local variables
--set @strShortest = @s1 
--set @intLenShortest = Len(@s1)
--set @strLongest = @s2
--set @intLenLongest = Len(@s2)

-- There are no strings to compare i.e. NULL V's Empty String OR NULL V's NULL OR Empty String V's Empty String
If ((@s1 is null) and (@s2 is null)) OR ((@s1 = NULL) and (@s2 = '')) OR ((@s1 = '') and (@s2 = NULL)) OR ((@s1 = '') and (@s2 = ''))
	begin
		return (NULL)
	end

--There is one string to compare i.e. NULL V's 'Not empty String'
If ((@s1 is null) and (len(@s2) > 0)) OR ((@s2 = NULL) and (len(@s1) > 0))
	begin
		return (0)
	end
--Put input strings into relevant variables
/*
If @intLenLongest < @intLenShortest 
	begin
		set @strTemp = @s1 			
		set @s1 = @s2 				
		set @s2 = @strTemp 			
		set @intTemp = @intLenShortest 	
		set @intLenShortest = @intLenLongest 	
		set @intLenLongest = @intTemp 		
		set @strShortest = @s1 			
		set @strLongest = @s2 
	end
*/
 

	







--Calculate max score generated for an exact match comparison
set @1CharMaxScore = @intLenLongest * @intLenLongest             	--max score comparing string in blocks of 1 char
set @2CharMaxScore = (@intLenLongest - 1) * (@intLenLongest - 1)  	--max score comparing string in blocks of 2 chars
set @3CharMaxScore = (@intLenLongest - 2) * (@intLenLongest - 2) 	--max score comparing string in blocks of 3 chars

--initialise counter variable

set @iCounter = 1

set @strMaskLongest = @StrLongest

--loop through short string 1 char at a time	
while (@iCounter <= @intLenShortest)

	begin
		set @intMatchPos = charindex(substring(@strShortest, @iCounter, 1), @strMaskLongest)
			
		If @intMatchPos > 0 --a matching char
			begin
				set @1CharScore = (@1CharScore + @intLenLongest - Abs(@iCounter - @intMatchPos))
				/* Mask matched char with ";" so it cannot be compared again */
				set @strMaskLongest = Left(@strMaskLongest, (@intMatchPos - 1)) + ';' + Right(@strMaskLongest, (@intLenLongest - @intMatchPos))
			end
	
		set @iCounter = @iCounter + 1
		continue
	end        

If (@1CharScore = 0)
	begin
		return (0)
	end

--loop through strings 2 chars at a time

set @strMaskLongest = @strLongest 				--Remove masking from longest string
set @lenLongString = @intLenLongest - 1 	--The second from last char will be the final iteration if you are comparing in chunks of 2chars
set @iCounter = 1				--Reset counter variable

while (@iCounter <= (@intLenShortest - 1))	--The last iteration will be for the second to last char as we are comparing 2 char chunks
	
	begin
		set @strComparison = substring(@strShortest, @iCounter, 2)		--get portion of smallest string in chunks of 2
		set @intMatchPos = charindex(@strComparison, @strMaskLongest)		--get position of comparison string within longest string
			
		If @intMatchPos > 0 
			begin
			      	set @2CharScore = @2CharScore + (@lenLongString - Abs(@iCounter - @intMatchPos))
				set @strMaskLongest = Left(@strMaskLongest, (@intMatchPos - 1)) + ';' + Right(@strMaskLongest, (@intLenLongest - @intMatchPos))
			end
		
		set @iCounter = @iCounter + 1
		continue	
	end

--if no score based on 2 chars there will be no score based on 3 chars so exit
If (@2CharScore = 0)
	begin
	return (100 * ((@1CharScore + @2CharScore) / (@1CharMaxScore + @2CharMaxScore)))
	end

set @strMaskLongest = @strLongest				--Remove masking from longest string 
set @lenLongString2 = @intLenLongest - 2 	--The third from last char will be the final iteration if you are comparing in chunks of 3chars
set @iCounter = 1				--Reset counter variable

while (@iCounter <= (@intLenShortest - 2))	--The last iteration will be for the third to last char as we are comparing 3 char chunks
	
	begin
		set @strComparison = substring(@strShortest, @iCounter, 3)
		set @intMatchPos = charindex(@strComparison, @strMaskLongest)
		
		If @intMatchPos > 0 
			begin
				set @3CharScore = @3CharScore + (@lenLongString2 - Abs(@iCounter - @intMatchPos))
				set @strMaskLongest = Left(@strMaskLongest, (@intMatchPos - 1)) + ';' + Right(@strMaskLongest, (@intLenLongest - @intMatchPos))
			end        
	
	    	set @iCounter = @iCounter + 1
		continue	
	end
--add weightings

return (100 * ((@1CharScore + (@2CharScore * 5) + (@3CharScore * 10)) / (@1CharMaxScore + (@2CharMaxScore * 5) + (@3CharMaxScore * 10))))

END




