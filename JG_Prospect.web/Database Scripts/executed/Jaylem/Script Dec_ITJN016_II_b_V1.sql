USE [JGBS_Dev]
GO
-- =============================================
-- Author:		Jaylem
-- Create date: 13-Dec-2016
-- Description:	Returns all/selected Active Designation 
-- =============================================
CREATE PROCEDURE [dbo].[UDP_GetAllActiveDesignationByFilter]
	@DepartmentID As Int,
	@DesignationID As Int
AS
BEGIN
	SET NOCOUNT ON;	
	
	SELECT ds.ID
	,ds.DesignationName
	,ds.IsActive
	,ds.DepartmentID
	,dt.DepartmentName
	FROM tbl_Designation ds
	INNER JOIN tbl_Department dt On dt.ID = ds.DepartmentID
	WHERE ds.IsActive=1
	AND ds.ID = (CASE WHEN @DesignationID=0 THEN ds.ID ELSE @DesignationID END)
	AND ds.DepartmentID = (CASE WHEN @DepartmentID=0 THEN ds.DepartmentID ELSE @DepartmentID END)

END

GO
ALTER TABLE [dbo].[tblInstallUsers] ADD IsFirstTime [bit] NULL CONSTRAINT [DF_tblInstallUsers_IsFirstTime]  DEFAULT (1);  
GO
ALTER TABLE [dbo].[tblTaskDesignations] ADD DesignationID [int] NULL;  
GO

IF(select top 1 ID from tblInstallUsers where email like '%jgrove@jmgroveconstruction.com%') IS NULL
BEGIN 
	Insert Into tblInstallUsers (Email,[Password],Usertype,Designation,[Status],Phone,[Address],FristName,DesignationID)
	Values('jgrove@jmgroveconstruction.com','321','Admin','Admin','Active','998732998','US','J',1)
END
ELSE
BEGIN 
	update tblInstallUsers Set [Password]='321',Usertype='Admin',Designation='Admin',[Status]='Active',DesignationID=1
	where email like '%jgrove@jmgroveconstruction.com%'
END

GO
-- =============================================    
-- Author: ALI SHAHABAS  
-- Create date: 26-JUNE-2016  
-- Updated By: Jaylem
-- Updated date: 13-Dec-2016  
-- Description: SP_GetInstallUsers    
-- =============================================    
ALTER PROCEDURE [dbo].[SP_GetInstallUsers]    
	@Key int,  
	@Designations varchar(4000)  
AS    
BEGIN    

	IF @Key = 1  
	BEGIN
		SELECT
			DISTINCT(Designation) AS Designation 
		FROM tblinstallUsers 
		WHERE Designation IS NOT NULL     
		ORDER BY Designation
	END
	ELSE IF @Key = 2  
	BEGIN
		SELECT 
			DISTINCT FristName + ' ' + LastName AS FristName, Id , [Status] 
		FROM tblinstallUsers 
		WHERE  
			(FristName IS NOT NULL OR FristName <> '' )  AND 
			(
				tblinstallUsers.[Status] = 'OfferMade' OR 
				tblinstallUsers.[Status] = 'Offer Made' OR 
				tblinstallUsers.[Status] = 'Active' OR 
				tblinstallUsers.[Status] = 'Interview Date' OR 
				tblinstallUsers.[Status] = 'InterviewDate'
			) AND 
			(
				Designation IN (SELECT Item FROM dbo.SplitString(@Designations,','))
				OR
				DesignationID IN (SELECT Item FROM dbo.SplitString(@Designations,','))
			)
		ORDER BY FristName + ' ' + LastName
	END
END

GO
-- =============================================    
-- Updated By: Jaylem
-- Updated date: 13-Dec-2016  
-- Description: UDP_GetallInstallusersdataNew    
-- =============================================   
ALTER PROCEDURE [dbo].[UDP_GetallInstallusersdataNew] 
AS
BEGIN

	SELECT t.Id,t.FristName,t.LastName,t.Phone,t.Zip,t.Designation,t.Status,t.PrimeryTradeId,d.TradeName AS 'PTradeName',t.HireDate,t.InstallId,t.picture,t.CreatedDateTime, Isnull(Source,'') AS Source,
	SourceUser, ISNULL(U.Username,'')  AS AddedBy,
	InterviewDetail = case when (t.Status='InterviewDate' or t.Status='Interview Date') then coalesce(RejectionDate,'') + ' ' + coalesce(InterviewTime,'') else '' end,
	RejectDetail = case when (t.Status='Rejected' ) then coalesce(RejectionDate,'') + ' ' + coalesce(RejectionTime,'') + ' ' + '-' + coalesce(ru.LastName,'') else '' end,
	de.DesignationName,t.DesignationID

	FROM tblInstallUsers t 
	LEFT OUTER JOIN Trades d ON d.Id = t.PrimeryTradeId
	LEFT OUTER JOIN tblUsers U ON U.Id = t.SourceUser
	LEFT OUTER JOIN tblUsers ru on t.RejectedUserId=ru.Id
	LEFT OUTER JOIN tbl_Designation de ON de.ID=t.DesignationID
	WHERE  t.Status <> 'Deactive'
	and (t.usertype = 'installer' OR t.usertype = 'Prospect' OR (t.usertype IS NULL AND t.Designation = 'SubContractor') OR (t.usertype IS NULL AND t.Designation = 'Installer'))
	ORDER BY Id DESC
	  
END

GO

ALTER PROCEDURE [dbo].[sp_FilterHrData]
	@status nvarchar(250)='',
	@designation nvarchar(500)='',
	@fromdate date,
	@todate date
AS
BEGIN
	
	SELECT t.Id,t.FristName, t.LastName,t.Designation,t.Status ,t.Source, ISNULL(U.Username,'')  AS AddedBy, t.CreatedDateTime 
	FROM tblInstallUsers t 
		LEFT OUTER JOIN tblUsers U ON U.Id = t.SourceUser
		LEFT OUTER JOIN tblUsers ru on t.RejectedUserId=ru.Id
	WHERE t.Status=@status 
		AND 
			(
				t.Designation=(Case When @designation = 'ALL' Then t.Designation Else @designation End)
				OR
				t.DesignationID=(Case When @designation IN ('All','0') Then t.DesignationID Else @designation End)
			)
		AND CAST(t.CreatedDateTime as date) >= CAST( @fromdate  as date) 
		AND CAST (t.CreatedDateTime  as date) <= CAST( @todate  as date)
	
END
 
GO


ALTER PROCEDURE [dbo].[UDP_AddInstallUser]  
	@FristName varchar(50),  
	@LastName varchar(50),  
	@Email varchar(100),  
	@phone varchar(20),  
	@phonetype char(15),
	@address varchar(100),  
	@Zip varchar(10),  
	@State varchar(30),  
	@City varchar(30),  

	@Zip2 varchar(10) = null,  
	@State2 varchar(30) = null,  
	@City2 varchar(30) = null,
	  

	@password varchar(50),  
	@designation varchar(50),  
	@status varchar(20),  
	@Picture varchar(max),  
	@Attachements varchar(max),
	@bussinessname varchar(100),
	@ssn varchar(20),
	@ssn1 varchar(20),
	@ssn2 varchar(20),
	@signature varchar(25),
	@dob varchar(20),
	@citizenship varchar(50),
	@ein1 varchar(20),
	@ein2 varchar(20), 
	@a varchar(20),
	@b varchar(20),
	@c varchar(20),
	@d varchar(20),
	@e varchar(20),
	@f varchar(20),
	@g varchar(20),
	@h varchar(20),
	@i varchar(20),
	@j varchar(20),
	@k varchar(20),
	@maritalstatus varchar(20),
	@PrimeryTradeId int = 0,
	@SecondoryTradeId varchar(200) = '',
	@Source	varchar(MAX)='',
	@Notes	varchar(MAX)='',
	@StatusReason varchar(MAX) = '',
	@GeneralLiability	varchar(MAX) = '',
	@PCLiscense	varchar(MAX) = '',
	@WorkerComp	varchar(MAX) = '',
	@HireDate varchar(50) = '',
	@TerminitionDate varchar(50) = '',
	@WorkersCompCode varchar(20) = '',
	@NextReviewDate	varchar(50) = '',
	@EmpType varchar(50) = '',
	@LastReviewDate	varchar(50) = '',
	@PayRates varchar(50) = '',
	@ExtraEarning varchar(max) = '',
	@ExtraEarningAmt varchar(max) = 0,
	@PayMethod varchar(50) = '',
	@Deduction VARCHAR(MAX) = '',
	@DeductionType varchar(50) = '',
	@AbaAccountNo varchar(50) = '',
	@AccountNo varchar(50) = '',
	@AccountType varchar(50) = '',
	@InstallId VARCHAR(MAX) = '',
	@PTradeOthers varchar(100) = '',
	@STradeOthers varchar(100) = '',
	@DeductionReason varchar(MAX) = '',
	@SuiteAptRoom varchar(10) = '',
	@FullTimePosition int = 0,
	@ContractorsBuilderOwner VARCHAR(500) = '',
	@MajorTools VARCHAR(250) = '',
	@DrugTest bit = null,
	@ValidLicense bit = null,
	@TruckTools bit = null,
	@PrevApply bit = null,
	@LicenseStatus bit = null,
	@CrimeStatus bit = null,
	@StartDate VARCHAR(50) = '',
	@SalaryReq VARCHAR(50) = '',
	@Avialability VARCHAR(50) = '',
	@ResumePath VARCHAR(MAX) = '',
	@skillassessmentstatus bit = null,
	@assessmentPath VARCHAR(MAX) = '',
	@WarrentyPolicy  VARCHAR(50) = '',
	@CirtificationTraining VARCHAR(MAX) = '',
	@businessYrs decimal = 0,
	@underPresentComp decimal = 0,
	@websiteaddress VARCHAR(MAX) = '',
	@PersonName VARCHAR(MAX) = '',
	@PersonType VARCHAR(MAX) = '',
	@CompanyPrinciple VARCHAR(MAX) = '',
	@UserType VARCHAR(25) = '',
	@Email2	varchar(70)	= '',
	@Phone2	varchar(70)	= '',
	@CompanyName	varchar(100) = '',
	@SourceUser	varchar(10)	= '',
	@DateSourced	varchar(50)	= '',
	@InstallerType varchar(20) = '',
	@BusinessType varchar(50) = '',
	@CEO varchar(100) = '',
	@LegalOfficer	varchar(100) = '',
	@President	varchar(100) = '',
	@Owner	varchar(100) = '',
	@AllParteners	varchar(MAX) = '',
	@MailingAddress	varchar(100) = '',
	@Warrantyguarantee	bit = null,
	@WarrantyYrs	int = 0,
	@MinorityBussiness	bit = null,
	@WomensEnterprise	bit = null,
	@InterviewTime varchar(20) ='',
	@ActivationDate	varchar(50)	= '',
	@UserActivated	varchar(100) = '',
	@LIBC VARCHAR(5) = '',

	@CruntEmployement bit = null,
	@CurrentEmoPlace varchar(100) = '',
	@LeavingReason varchar(MAX) = '',
	@CompLit bit = null,
	@FELONY	bit = null,
	@shortterm	varchar(250) = '',
	@LongTerm	varchar(250) = '',
	@BestCandidate	varchar(MAX) = '',
	@TalentVenue	varchar(MAX) = '',
	@Boardsites	varchar(300) = '',
	@NonTraditional	varchar(MAX) = '',
	@ConSalTraning	varchar(100) = '',
	@BestTradeOne	varchar(50) = '',
	@BestTradeTwo	varchar(50) = '',
	@BestTradeThree	varchar(50) = '',

	@aOne	varchar(50)	= '',
	@aOneTwo	varchar(50)	= '',
	@bOne	varchar(50)	= '',
	@cOne	varchar(50)	= '',
	@aTwo	varchar(50)	= '',
	@aTwoTwo	varchar(50)	= '',
	@bTwo	varchar(50)	= '',
	@cTwo	varchar(50)	= '',
	@aThree	varchar(50)	= '',
	@aThreeTwo	varchar(50)	= '',
	@bThree	varchar(50)	= '',
	@cThree	varchar(50)	= '',
	@RejectionDate	varchar(50)	='',
	@RejectionTime	varchar(50)	='',
	@RejectedUserId  int = 0,
	@TC bit = null,
	@ExtraIncomeType varchar(MAX) = '',
	@AddedBy int = 0,
	@PositionAppliedFor varchar(50)	='',
	@DesignationID int=0,
	@Id int out,
	@result bit output  

AS 
BEGIN  

	DECLARE @MaxId int = 0

	INSERT INTO tblInstallUsers   
		(  
			FristName,LastName,Email,Phone,phonetype,[Address],Zip,[State],[City],
			Zip2,[State2],[City2],
			[Password],Designation,[Status],Picture,Attachements,Bussinessname,SSN,SSN1,SSN2,[Signature]
			,DOB,Citizenship,EIN1,EIN2,A,B,C,D,E,F,G,H,[5],[6],[7],maritalstatus,PrimeryTradeId
			,SecondoryTradeId,Source,Notes,StatusReason,GeneralLiability,PCLiscense,WorkerComp,HireDate,TerminitionDate,WorkersCompCode,NextReviewDate,EmpType,LastReviewDate
			,PayRates,ExtraEarning,ExtraEarningAmt,PayMethod,Deduction,DeductionType,AbaAccountNo,AccountNo,AccountType
			,InstallId,PTradeOthers,STradeOthers,DeductionReason,SuiteAptRoom,FullTimePosition,ContractorsBuilderOwner,MajorTools,DrugTest,ValidLicense,TruckTools
			,PrevApply,LicenseStatus,CrimeStatus,StartDate,SalaryReq,Avialability,ResumePath,skillassessmentstatus,assessmentPath,WarrentyPolicy,CirtificationTraining
			,businessYrs,underPresentComp,websiteaddress,PersonName,PersonType,CompanyPrinciple,UserType,Email2,Phone2,CompanyName,SourceUser,DateSourced,InstallerType
			,BusinessType,CEO,LegalOfficer,President,Owner,AllParteners,MailingAddress,Warrantyguarantee,WarrantyYrs,MinorityBussiness,WomensEnterprise,InterviewTime
			,ActivationDate,UserActivated,LIBC,CruntEmployement,CurrentEmoPlace,LeavingReason,CompLit,FELONY,shortterm,LongTerm,BestCandidate,TalentVenue,Boardsites
			,NonTraditional,ConSalTraning,BestTradeOne,BestTradeTwo,BestTradeThree,aOne,aOneTwo,bOne,cOne,aTwo,aTwoTwo,bTwo,cTwo,aThree,aThreeTwo,bThree,cThree
			,RejectionDate,RejectionTime,RejectedUserId,TC,ExtraIncomeType
			,PositionAppliedFor,DesignationID
		)  
	VALUES  
		(  
			@FristName,@LastName,@Email,@phone,@phonetype,@address,@Zip,@State,@City,
			@Zip2,@State2,@City2,
			@password,@designation,@status,@Picture,@Attachements,@bussinessname,@ssn,@ssn1,@ssn2,@signature
			,@dob,@citizenship,@ein1,@ein2,@a,@b,@c,@d,@e,@f,@g,@h,@i,@j,@k,@maritalstatus,@PrimeryTradeId,@SecondoryTradeId,@Source,@Notes,@StatusReason,@GeneralLiability
			,@PCLiscense,@WorkerComp,@HireDate,@TerminitionDate,@WorkersCompCode,@NextReviewDate,@EmpType,@LastReviewDate
			,@PayRates,@ExtraEarning,@ExtraEarningAmt,@PayMethod,@Deduction,@DeductionType,@AbaAccountNo,@AccountNo,@AccountType,@InstallId,@PTradeOthers,@STradeOthers
			,@DeductionReason,@SuiteAptRoom,@FullTimePosition,@ContractorsBuilderOwner,@MajorTools,@DrugTest,@ValidLicense,@TruckTools,@PrevApply,@LicenseStatus
			,@CrimeStatus,@StartDate,@SalaryReq,@Avialability,@ResumePath,@skillassessmentstatus,@assessmentPath,@WarrentyPolicy,@CirtificationTraining,@businessYrs
			,@underPresentComp,@websiteaddress,@PersonName,@PersonType,@CompanyPrinciple,@UserType,@Email2,@Phone2,@CompanyName,@SourceUser,@DateSourced,@InstallerType
			,@BusinessType,@CEO,@LegalOfficer,@President,@Owner,@AllParteners,@MailingAddress,@Warrantyguarantee,@WarrantyYrs,@MinorityBussiness,@WomensEnterprise,@InterviewTime
			,@ActivationDate,@UserActivated,@LIBC,@CruntEmployement,@CurrentEmoPlace,@LeavingReason,@CompLit,@FELONY,@shortterm,@LongTerm,@BestCandidate,@TalentVenue
			,@Boardsites,@NonTraditional,@ConSalTraning,@BestTradeOne,@BestTradeTwo,@BestTradeThree,@aOne,@aOneTwo,@bOne,@cOne,@aTwo,@aTwoTwo,@bTwo,@cTwo,@aThree,@aThreeTwo
			,@bThree,@cThree,@RejectionDate,@RejectionTime,@RejectedUserId,@TC,@ExtraIncomeType
			,@PositionAppliedFor,@DesignationID
		) 

	SELECT @Id = SCOPE_IDENTITY();

	SELECT @MaxId = MAX(Id) FROM tblInstallUsers

	INSERT INTO [tblInstalledReport]([SourceId],[InstallerId],[Status])
	VALUES(Cast(@SourceUser as int),@MaxId,@status)

	IF @status = 'InterviewDate' OR @status = 'Interview Date'
	BEGIN
		INSERT INTO tbl_AnnualEvents(EventName,EventDate,EventAddedBy,ApplicantId)
		VALUES('InterViewDetails',@StatusReason,@AddedBy,@MaxId)--CAST(@SourceUser as int)(Added by Sandeep...)
	END

	SET @result ='1'  
  
	RETURN @result  
  
END

GO

ALTER PROCEDURE [dbo].[UDP_UpdateInstallUsers]  
	@id int,  
	@FristName varchar(50),  
	@LastName varchar(50),  
	@Email varchar(100),  
	@phone varchar(50),  
	@Address varchar(20),  
	@Zip varchar(10),  
	@State varchar(30),  
	@City varchar(30),  
	@password varchar(30),
	@designation varchar(30),
	@status varchar(30),
	@Picture varchar(max),  
	@attachement varchar(max),
	@bussinessname varchar(100),
	@ssn varchar(20),
	@ssn1 varchar(20),
	@ssn2 varchar(20),
	@signature varchar(25),
	@dob varchar(20),  
	@citizenship varchar(50),
	@ein1 varchar(20),
	@ein2 varchar(20), 
	@a varchar(20),
	@b varchar(20),
	@c varchar(20),
	@d varchar(20),
	@e varchar(20),
	@f varchar(20),
	@g varchar(20),
	@h varchar(20),
	@i varchar(20),
	@j varchar(20),
	@k varchar(20),
	@maritalstatus varchar(20),
	@PrimeryTradeId int = 0,
	@SecondoryTradeId int = 0,
	@Source	varchar(MAX)='',
	@Notes	varchar(MAX)='',
	@StatusReason varchar(MAX)='',
	@GeneralLiability	varchar(MAX) = '',
	@PCLiscense	varchar(MAX) = '',
	@WorkerComp	varchar(MAX) = '',
	@HireDate varchar(50) = '',
	@TerminitionDate varchar(50) = '',
	@WorkersCompCode varchar(20) = '',
	@NextReviewDate	varchar(50) = '',
	@EmpType varchar(50) = '',
	@LastReviewDate	varchar(50) = '',
	@PayRates varchar(50) = '',
	@ExtraEarning varchar(MAX) = '',
	@ExtraEarningAmt varchar(MAX) = 0,
	@PayMethod varchar(50) = '',
	@Deduction VARCHAR(MAX) = 0,
	@DeductionType varchar(50) = '',
	@AbaAccountNo varchar(50) = '',
	@AccountNo varchar(50) = '',
	@AccountType varchar(50) = '',
	@PTradeOthers varchar(100) = '',
	@STradeOthers varchar(100) = '',
	@DeductionReason varchar(MAX) = '',
	@SuiteAptRoom varchar(10) = '',
	@FullTimePosition int = 0,
	@ContractorsBuilderOwner VARCHAR(500) = '',
	@MajorTools VARCHAR(250) = '',
	@DrugTest bit = null,
	@ValidLicense bit = null,
	@TruckTools bit = null,
	@PrevApply bit = null,
	@LicenseStatus bit = null,
	@CrimeStatus bit = null,
	@StartDate VARCHAR(50) = '',
	@SalaryReq VARCHAR(50) = '',
	@Avialability VARCHAR(50) = '',
	@ResumePath VARCHAR(MAX) = '',
	@skillassessmentstatus bit = null,
	@assessmentPath VARCHAR(MAX) = '',
	@WarrentyPolicy  VARCHAR(50) = '',
	@CirtificationTraining VARCHAR(MAX) = '',
	@businessYrs decimal = 0,
	@underPresentComp decimal = 0,
	@websiteaddress VARCHAR(MAX) = '',
	@PersonName VARCHAR(MAX) = '',
	@PersonType VARCHAR(MAX) = '',
	@CompanyPrinciple VARCHAR(MAX) = '',
	@UserType VARCHAR(25) = '',
	@Email2	varchar(70)	= '',
	@Phone2	varchar(70)	= '',
	@CompanyName	varchar(100) = '',
	@SourceUser	varchar(10)	= '',
	@DateSourced	varchar(50)	= '',
	@InstallerType VARCHAR(20) = '',
	@BusinessType varchar(50) = '',
	@CEO varchar(100) = '',
	@LegalOfficer	varchar(100) = '',
	@President	varchar(100) = '',
	@Owner	varchar(100) = '',
	@AllParteners	varchar(MAX) = '',
	@MailingAddress	varchar(100) = '',
	@Warrantyguarantee	bit = null,
	@WarrantyYrs	int = 0,
	@MinorityBussiness	bit = null,
	@WomensEnterprise	bit = null,
	@InterviewTime varchar(20) ='',
	@LIBC VARCHAR(5) = '',
	@Flag int = 0,

	@CruntEmployement bit = null,
	@CurrentEmoPlace varchar(100) = '',
	@LeavingReason varchar(MAX) = '',
	@CompLit bit = null,
	@FELONY	bit = null,
	@shortterm	varchar(250) = '',
	@LongTerm	varchar(250) = '',
	@BestCandidate	varchar(MAX) = '',
	@TalentVenue	varchar(MAX) = '',
	@Boardsites	varchar(300) = '',
	@NonTraditional	varchar(MAX) = '',
	@ConSalTraning	varchar(100) = '',
	@BestTradeOne	varchar(50) = '',
	@BestTradeTwo	varchar(50) = '',
	@BestTradeThree	varchar(50) = '',

	@aOne	varchar(50)	= '',
	@aOneTwo	varchar(50)	= '',
	@bOne	varchar(50)	= '',
	@cOne	varchar(50)	= '',
	@aTwo	varchar(50)	= '',
	@aTwoTwo	varchar(50)	= '',
	@bTwo	varchar(50)	= '',
	@cTwo	varchar(50)	= '',
	@aThree	varchar(50)	= '',
	@aThreeTwo	varchar(50)	= '',
	@bThree	varchar(50)	= '',
	@cThree	varchar(50)	= '',
	@RejectionDate	varchar(50)	='',
	@RejectionTime	varchar(50)	='',
	@RejectedUserId  int = 0,
	@TC bit = null,
	@ExtraIncomeType varchar(MAX) = '',
	@PositionAppliedFor varchar(50) = '',
	@AddedBy int = 0,
	@DesignationID int=0,
	@result int output  
AS 
BEGIN  
	
	IF(Select ID FROM tblInstallUsers WHERE Id=@id) IS NOT NULL
	BEGIN
		UPDATE tblInstallUsers 
		SET 
		FristName=@FristName,LastName=@LastName,Email=@Email,Phone=@phone,[Address]=@Address,Zip=@Zip,
		[State]=@State,City=@City,[Password]=@password,Designation=@designation,
		[Status]=@status,Picture=@Picture,Attachements=@attachement,Bussinessname=@bussinessname,SSN=@ssn,SSN1=@ssn1,SSN2=@ssn2,[Signature]=@signature,DOB=@dob,
		Citizenship=@citizenship,EIN1=@ein1,EIN2=@ein2,A=@a,B=@b,C=@c,D=@d,E=@e,F=@f,G=@g,H=@h,[5]=@i,[6]=@j,[7]=@k,
		maritalstatus=@maritalstatus,
		PrimeryTradeId=@PrimeryTradeId,
		SecondoryTradeId=@SecondoryTradeId,
		[Source] = @Source,
		Notes = @Notes,
		StatusReason = @StatusReason,
		GeneralLiability = @GeneralLiability,
		PCLiscense = @PCLiscense,
		WorkerComp = @WorkerComp,
		HireDate = @HireDate,
		TerminitionDate = @TerminitionDate,
		WorkersCompCode = @WorkersCompCode,
		NextReviewDate = @NextReviewDate,
		EmpType = @EmpType,
		LastReviewDate = @LastReviewDate,
		PayRates = @PayRates,
		ExtraEarning = @ExtraEarning,
		ExtraEarningAmt = @ExtraEarningAmt,
		PayMethod = @PayMethod,
		Deduction = @Deduction,
		AbaAccountNo = @AbaAccountNo ,
		AccountNo = @AccountNo,
		AccountType = @AccountType,
		DeductionType = @DeductionType,
		PTradeOthers = @PTradeOthers,
		STradeOthers = @STradeOthers,
		DeductionReason = @DeductionReason,
		SuiteAptRoom = @SuiteAptRoom,
		FullTimePosition = @FullTimePosition
		,ContractorsBuilderOwner = @ContractorsBuilderOwner
		,MajorTools = @MajorTools
		,DrugTest = @DrugTest
		,ValidLicense = @ValidLicense
		,TruckTools = @TruckTools
		,PrevApply = @PrevApply
		,LicenseStatus = @LicenseStatus
		,CrimeStatus = @CrimeStatus
		,StartDate = @StartDate
		,SalaryReq = @SalaryReq
		,Avialability = @Avialability
		,ResumePath = @ResumePath
		,skillassessmentstatus = @skillassessmentstatus
		,assessmentPath = @assessmentPath
		,WarrentyPolicy = @WarrentyPolicy
		,CirtificationTraining = @CirtificationTraining
		,businessYrs = @businessYrs
		,underPresentComp = @underPresentComp
		,websiteaddress = @websiteaddress
		,PersonName = @PersonName
		,PersonType = @PersonType
		,CompanyPrinciple = @CompanyPrinciple
		,UserType = @UserType
		,Email2 = @Email2
		,Phone2 = @Phone2
		,CompanyName = @CompanyName
		,SourceUser = @SourceUser
		,DateSourced = @DateSourced
		,InstallerType = @InstallerType
		,BusinessType = @BusinessType
		,CEO = @CEO
		,LegalOfficer = @LegalOfficer
		,President = @President
		,[Owner] = @Owner
		,AllParteners = @AllParteners
		,MailingAddress = @MailingAddress
		,Warrantyguarantee = @Warrantyguarantee
		,WarrantyYrs = @WarrantyYrs
		,MinorityBussiness = @MinorityBussiness
		,WomensEnterprise = @WomensEnterprise
		,InterviewTime = @InterviewTime 
		,LIBC = @LIBC
		,CruntEmployement = @CruntEmployement,
		CurrentEmoPlace = @CurrentEmoPlace,
		LeavingReason = @LeavingReason,
		CompLit = @CompLit,
		FELONY = @FELONY,
		shortterm = @shortterm,
		LongTerm = @LongTerm,
		BestCandidate = @BestCandidate,
		TalentVenue = @TalentVenue,
		Boardsites = @Boardsites,
		NonTraditional = @NonTraditional,
		ConSalTraning = @ConSalTraning,
		BestTradeOne =  @BestTradeOne,
		BestTradeTwo = @BestTradeTwo,
		BestTradeThree = @BestTradeThree,

		aOne = @aOne,aOneTwo = @aOneTwo,bOne = @bOne,cOne = @cOne,aTwo = @aTwo,aTwoTwo = @aTwoTwo,bTwo = @bTwo,cTwo = @cTwo,aThree = @aThree,aThreeTwo = @aThreeTwo,
		bThree = @bThree,cThree = @cThree,

		RejectionDate = @RejectionDate,RejectionTime = @RejectionTime,RejectedUserId = @RejectedUserId,
		TC = @TC,ExtraIncomeType = @ExtraIncomeType,
		PositionAppliedFor = @PositionAppliedFor,
		DesignationID=@DesignationID
		WHERE Id=@id  

		IF @Flag <> 0
		BEGIN
			INSERT INTO [tblInstalledReport]([SourceId],[InstallerId],[Status])
			VALUES(Cast(@SourceUser as int),@id,@status)
		END

		IF @status = 'InterviewDate' OR @status = 'Interview Date'
		BEGIN
			--UPDATE tbl_AnnualEvents SET EventDate=@StatusReason where ApplicantId=@id
			INSERT tbl_AnnualEvents (EventName,EventDate,EventAddedBy,ApplicantId)values('InterViewDetails',@StatusReason,@AddedBy,@id)		
		END

		SET @result ='1'  

	END
	ELSE
	BEGIN         
		SET @result ='0'        
	END  
		
	RETURN @result  
 END
--modified/created by Other Party

GO

ALTER PROCEDURE [dbo].[UDP_GETInstallUserDetails]
	@id int
As 
BEGIN

	SELECT Id,FristName,Lastname,Email,[Address],Designation,
	[Status],[Password],Phone,Picture,Attachements,zip,[state],city,
	Bussinessname,SSN,SSN1,SSN2,[Signature],DOB,Citizenship,' ',
	EIN1,EIN2,A,B,C,D,E,F,G,H,[5],[6],[7],maritalstatus,PrimeryTradeId,SecondoryTradeId,Source,Notes,StatusReason,GeneralLiability,PCLiscense,WorkerComp,HireDate,TerminitionDate,WorkersCompCode,NextReviewDate,EmpType,LastReviewDate,PayRates,ExtraEarning,ExtraEarningAmt,PayMethod,Deduction,DeductionType,AbaAccountNo,AccountNo,AccountType,PTradeOthers,
	STradeOthers,DeductionReason,InstallId,SuiteAptRoom,FullTimePosition,ContractorsBuilderOwner,MajorTools,DrugTest,ValidLicense,TruckTools,PrevApply,LicenseStatus,CrimeStatus,StartDate,SalaryReq,Avialability,ResumePath,skillassessmentstatus,assessmentPath,WarrentyPolicy,CirtificationTraining,businessYrs,underPresentComp,websiteaddress,PersonName,PersonType,CompanyPrinciple,UserType,Email2,Phone2,CompanyName,SourceUser,DateSourced,InstallerType,BusinessType,CEO,LegalOfficer,President,Owner,AllParteners,MailingAddress,Warrantyguarantee,WarrantyYrs,MinorityBussiness,WomensEnterprise,InterviewTime,CruntEmployement,CurrentEmoPlace,LeavingReason,CompLit,FELONY,shortterm,LongTerm,BestCandidate,TalentVenue,Boardsites,NonTraditional,ConSalTraning,BestTradeOne,BestTradeTwo,BestTradeThree
	,aOne,aOneTwo,bOne,cOne,aTwo,aTwoTwo,bTwo,cTwo,aThree,aThreeTwo,bThree,cThree,TC,ExtraIncomeType,RejectionDate ,UserInstallId,PositionAppliedFor,
	DesignationID
	FROM tblInstallUsers 
	WHERE ID=@id

END

GO
-- =============================================
-- Author:		Yogesh Keraliya
-- Create date: 07152016
-- Description:	Will insert assigned designations for given task
-- =============================================

ALTER PROCEDURE [dbo].[usp_InsertTaskDesignations] 
(
	@TaskId int ,
	@Designations varchar(4000) ,
	@TaskIDCode varchar(5)
)	
AS
BEGIN

	DECLARE @InstallId VARCHAR(50) = NULL

	SELECT @InstallId = InstallId
	FROM tblTask
	WHERE TaskId = @TaskId

	IF @InstallId IS NULL
	BEGIN
		-- get sequence of last entered task for perticular designation.
		DECLARE @DesSequence bigint

		SELECT @DesSequence = ttds.LastSequenceNo FROM dbo.tblTaskDesignationSequence ttds WHERE ttds.DesignationCode = @TaskIDCode

		-- if it is first time task is entered for designation start from 001.
		IF(@DesSequence IS NULL)
		BEGIN
			SET @DesSequence = 0  
		END

		SET @DesSequence = @DesSequence + 1  

		UPDATE tblTask
			SET InstallId = @TaskIDCode + Right('00' + CONVERT(NVARCHAR, @DesSequence), 3)
		WHERE TaskId=@TaskId

		-- INCREMENT SEQUENCE NUMBER FOR DESIGNATION TO USE NEXT TIME
		IF NOT EXISTS( 
						SELECT ttds.TaskDesigSequenceId 
						FROM dbo.tblTaskDesignationSequence ttds 
						WHERE ttds.DesignationCode = @TaskIDCode 
					 )
		BEGIN
			INSERT INTO dbo.tblTaskDesignationSequence
			(
    
				DesignationCode,
				LastSequenceNo
			)
			VALUES
			(
				@TaskIDCode,
				@DesSequence
			) 
		END
		ELSE		
		BEGIN
			UPDATE dbo.tblTaskDesignationSequence
			SET
				dbo.tblTaskDesignationSequence.LastSequenceNo = @DesSequence
			WHERE dbo.tblTaskDesignationSequence.DesignationCode = @TaskIDCode 
		END
	END

	-- REMOVE ALREADY ADDED DESIGNATIONS IF ANY
	DELETE FROM tblTaskDesignations
	WHERE  (TaskId = @TaskId)

	-- insert comma seperated multiple designations for given task.
	INSERT INTO tblTaskDesignations (TaskId, Designation,DesignationID)
	SELECT @TaskId , (Select top 1 DesignationName From tbl_Designation Where ID=item), item 
	FROM dbo.SplitString(@Designations,',') ss 

END

GO

ALTER ProcEDURE [dbo].[UDP_GetInstallerUserDetailsByLoginId]
	@loginId varchar(50) 
AS
BEGIN
	
	SELECT Id,FristName,Lastname,Email,Address,Designation,[Status],
		[Password],[Address],Phone,Picture,Attachements,usertype , Picture,IsFirstTime,DesignationID
	FROM tblInstallUsers 
	WHERE (Email = @loginId )  
	 AND 
	(Status='OfferMade' OR Status='Offer Made' OR Status='Active' OR Status = 'InterviewDate')

 
	--# This query does not make sense, the guy was really stupid.
	/*SELECT Id,FristName,Lastname,Email,Address,Designation,[Status],
		[Password],[Address],Phone,Picture,Attachements,usertype 
	from tblInstallUsers 
	where (Email = @loginId and Status='Active')  OR 
	(Email = @loginId AND (Designation = 'SubContractor' OR Designation='Installer') AND 
	(Status='OfferMade' OR Status='Offer Made' OR Status='Active'))*/
END

GO

ALTER PROCEDURE [dbo].[UDP_changepassword]
	--@usertype varchar(20),
	@loginid varchar(50),
	@password varchar(50),
	@IsCustomer bit,
	@result int output
AS BEGIN

	If @IsCustomer = 0
	BEGIN
		IF EXISTS (SELECT Id FROM tblUsers WHERE Id=@loginid)
		BEGIN
			UPDATE tblInstallUsers Set [Password]=@password,IsFirstTime=0 WHERE Id = @loginid
			Set @result ='1'
		END
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT Id FROM new_customer WHERE Id=@loginid)
		BEGIN
			UPDATE new_customer Set [Password]=@password,IsFirstTime=0 WHERE Id=@loginid
			Set @result ='1'
		END
	END
     
    return @result

 END

GO
-- =============================================
-- Author:		Jaylem
-- Create date: 05-Dec-2016
-- Description:	Update password
-- =============================================
ALTER PROCEDURE [dbo].[UDP_ForgotPasswordReset] 
	@Login_Id varchar(50) = '', 
	@NewPassword varchar(50) = '', 
	@IsCustomer Bit,
	@result int output
AS
BEGIN
	SET NOCOUNT ON;
	Set @result ='0'

	If @IsCustomer = 0
	BEGIN
		IF EXISTS (SELECT Id FROM tblInstallUsers WHERE Email=@Login_Id)
		BEGIN
			UPDATE tblInstallUsers Set [Password]=@NewPassword,IsFirstTime=1 WHERE Email = @Login_Id
			Set @result ='1'
		END
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT Id FROM new_customer WHERE (Email = @Login_Id OR CellPh = @Login_Id) AND Email != 'noEmail@blankemail.com')
		BEGIN
			UPDATE new_customer Set [Password]=@NewPassword,IsFirstTime=1 WHERE (Email = @Login_Id OR CellPh = @Login_Id) AND Email != 'noEmail@blankemail.com'
			Set @result ='1'
		END
	END

	RETURN @result

END

