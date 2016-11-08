  Use SchoolzillaDatasets

/*ADD*/
    SELECT  
	   [ID]
      ,[SchoolYear]
      ,[SystemStudentID]
      ,[TestType]
      ,[TestSubType]
      ,[TestPeriod]
      ,[TestDate]
      ,[TestSubjectGroup]
      ,[TestSubject]
      ,[TestGradeLevel]
      ,[TestName]
      ,[TestScore]
      ,[RawScore]
      ,[ScaleScore]
      ,[ProficincyLevelScore]
      ,[PercentScore]
      ,[PercentileScore]
      ,[PointsPossible]
      ,[ProficiencyLevelCode]
      ,[ProficiencyLevel]
      ,[Level]
      ,[LetterScore]
      ,[IsPreAF]
      ,[AthenaFlag]
      ,[TestScoreType]
      ,[LastUpdated]
      ,[MostRecent]
      ,[SchoolYear4Digit]
      ,[SystemTestID]
      ,[Fullname]
      ,[gradelevel],
      case 
      when [SchoolName]='Elm City College Prep ES' then 'Elm City College Prep K-4'
      else [SchoolName] end as SchoolName
      ,[schoollevel]
      ,[SchoolRegion]
    INTO    #AllAssessments
    FROM    kpi.AllAssessments;
    
    
    select count (schoolname), schoolname
    from #AllAssessments
    group by SchoolName
    
   

    DECLARE @KPIMonth DATE;
    SET @KPIMonth = '2016-Oct-01'; --Change this to 2015-Aug-01 for 2014-15 Run--
	
    DECLARE @CurrentYear NCHAR(10); -- Change this to 2014-2015 for 2014-15 Run--
    SET @CurrentYear = '2016-2017';
/***SET TARGETS AND CYCLES**/
/*STEP*/
    DECLARE @STEPCYCLE NCHAR(10);
    SET @STEPCYCLE = 'Cycle 1';

/*MAP*/
    DECLARE @MAPCycle NCHAR(10);
    SET @MAPCycle = 'Fall';
    
    DECLARE @MAPTarget FLOAT;
    SET @MAPTarget = 75;

/*IA Cycle*/
    DECLARE @IACycle NCHAR(10);
    SET @IACycle = 'IA1';

    DECLARE @8IATarget FLOAT;
    SET @8IATarget = 0.75;


/*SAT*/
	DECLARE @SATTarget FLOAT;
    SET @SATTarget = 1120;
	
    DECLARE @SATEssayTarget FLOAT;
    SET @SATEssayTarget = 16;
    
    
   /**

/* ----------------------------- BEGIN AP EOY Code----------------------------------------*/

																	-- Change School Year --
    SELECT  *
    INTO    #AP
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'AP' )
            AND SchoolYear = @CurrentYear;
																	 -- Change School Year --	
																	 
/* REMOVE GRADES WHO ARE NOT SUPPOSED TO TAKE AP*/

    SELECT  *
    INTO    #AP0
    FROM    #AP
    WHERE   ( TestSubject = 'English Language and Composition'
              AND gradelevel = '12th'
              OR TestSubject = 'English Literature and Composition'
              AND gradelevel = '11th'
              OR TestSubject IN ( 'Statistics', 'Calculus AB' )
              AND gradelevel = '12th'
              OR TestSubject = 'Research'
              AND gradelevel = '11th'
              OR --CHANGE TEST SUBJECT WHEN THIS SUBJECT STARTS EXISTING -- 
              TestSubject IN ( 'Biology', 'Chemistry', 'Physics 1' )
              AND gradelevel = '12th'
              OR TestSubject = 'Seminar'
              AND gradelevel = '10th'
              OR --CHANGE TEST SUBJECT WHEN THIS SUBJECT STARTS EXISTING -- 
              TestSubject = 'United States History'
              AND gradelevel = '11th'
              OR TestSubject = 'World History'
              AND gradelevel = '10th'
            );

								 

/* Select MAX for AP Math and AP Science + COMBINE IT WITH REST OF SUBJECTS */
	-- AP Math = Max of Calculus and Statistics

    SELECT  SchoolYear AS SchoolYear
          , SystemStudentID AS SystemStudentID
          , 'AP Math' AS TestSubject
          , Fullname AS Fullname
          , gradelevel AS GradeLevel
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , MAX(TestScore) AS Testscore
    INTO    #APMathMax
    FROM    #AP0
    WHERE   TestSubject IN ( 'Statistics', 'Calculus AB' )
    GROUP BY SchoolYear
          , SystemStudentID
          , Fullname
          , GradeLevel
          , SchoolName
          , SchoolLevel
          , SchoolRegion;


	-- AP Science (Biology, Chemistry, Physics) 

    SELECT  SchoolYear AS SchoolYear
          , SystemStudentID AS SystemStudentID
          , 'AP Science' AS TestSubject
          , Fullname AS Fullname
          , gradelevel AS GradeLevel
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , MAX(TestScore) AS Testscore
    INTO    #APSciMax
    FROM    #AP0
    WHERE   TestSubject IN ( 'Biology', 'Chemistry', 'Physics 1' )
    GROUP BY SchoolYear
          , SystemStudentID
          , Fullname
          , GradeLevel
          , SchoolName
          , SchoolLevel
          , SchoolRegion;


	-- Take All other Tests 

    SELECT  SchoolYear AS SchoolYear
          , SystemStudentID AS SystemStudentID
          , TestSubject AS TestSubject
          , Fullname AS Fullname
          , gradelevel AS GradeLevel
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , MAX(TestScore) AS Testscore
    INTO    #APOther
    FROM    #AP0
    WHERE   TestSubject NOT IN ( 'Biology', 'Chemistry', 'Physics 1',
                                 'Statistics', 'Calculus AB' )
    GROUP BY SchoolYear
          , SystemStudentID
          , TestSubject
          , Fullname
          , GradeLevel
          , SchoolName
          , SchoolLevel
          , SchoolRegion;


	-- Union AP as #AP1
    SELECT  *
    INTO    #AP1
    FROM    ( SELECT    *
              FROM      #APMathMax
              UNION
              SELECT    *
              FROM      #APSciMax
              UNION
              SELECT    *
              FROM      #APOther
            ) a;




	-- Dummy for Above3

    SELECT  *
          , CASE WHEN Testscore >= 3 THEN 1
                 ELSE 0
            END AS Above3
    INTO    #AP2
    FROM    #AP1;


/* Calculate Averages different levels*/
	


	-- AP NETWORK-- 
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    INTO    #AP3
    FROM    #AP2
    GROUP BY TestSubject
    UNION ALL

	-- AP GRADE--
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , SchoolLevel AS SchoolLevel
          , 'All' AS [State]
          , GradeLevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #AP2
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL

	-- AP STATE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #AP2
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL

	-- AP SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , SchoolLevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #AP2
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL


	-- AP SCHOOL --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #AP2
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	
	-- AP STATE x SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #AP2
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	-- AP BY STATE x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS [State]
          , GradeLevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #AP2
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL


	-- AP BY SCHOOL x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS [State]
          , GradeLevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #AP2
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel;



/*Assign Metric IDs based on Test Subject, then drop test subject*/

    SELECT  CASE WHEN Test = 'AP Math' THEN 'APMA'
                 WHEN Test = 'AP Science' THEN 'APSC'
                 WHEN Test = 'English Language and Composition' THEN 'APLC'
                 WHEN Test = 'English Literature and Composition' THEN 'APLT'
                 WHEN Test = 'Research' THEN 'APRS'
                 WHEN Test = 'Seminar' THEN 'APSM'
                 WHEN Test = 'United States History' THEN 'APUS'
                 WHEN Test = 'World History' THEN 'APWH'
            END AS Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , Test
          , GradeLevel
          , Actual
    INTO    #APFinal
    FROM    #AP3;




	/* ----------------------------- END AP EOY Code----------------------------------------*/


/* ----------------------------- BEGIN NY ST CODE----------------------------------------*/

																	
    SELECT  *
    INTO    #NYS
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'NY ST' )
            AND SchoolYear = @CurrentYear
            AND TestScoreType = 'Test'
            AND TestSubject NOT IN ( 'Science' );
																	 -- Change School Year --	


	-- Dummy for Proficient


    SELECT  *
          , CASE WHEN TestScore >= 3 THEN 1
                 ELSE 0
            END AS Above3
    INTO    #NYS1
    FROM    #NYS;


/* Calculate Averages different levels*/
	

	-- NY NETWORK-- 
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    INTO    #NYS2
    FROM    #NYS1
    GROUP BY TestSubject
    UNION ALL

	-- NY GRADE--
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #NYS1
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL

	-- NY STATE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #NYS1
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL

	-- NY SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #NYS1
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL


	-- NY SCHOOL --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #NYS1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	
	-- NY STATE x SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #NYS1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	-- NY BY STATE x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #NYS1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL


	-- NY BY SCHOOL x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #NYS1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel;



/*Assign Metric IDs based on Test Subject, then drop test subject*/

    SELECT  CASE WHEN Test = 'ELA' THEN 'NYSE'
                 WHEN Test = 'Math' THEN 'NYSM'
            END AS Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , Test
          , GradeLevel
          , Actual
    INTO    #NYSFinal
    FROM    #NYS2;



/* ----------------------------- END NY ST CODE----------------------------------------*/
	
/* ----------------------------- BEGIN SBAC CODE----------------------------------------*/
												
    SELECT  *
    INTO    #SBAC
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'SBAC' )
            AND SchoolYear = @CurrentYear
            AND TestScoreType = 'Test'
            AND TestSubject NOT IN ( 'Science' )
            AND TestScore IS NOT NULL
            AND TestGradeLevel NOT IN ( '11th' );
																	 	


	/*TEMP FIX FOR DUPS -- DELETE ONCE SZ FIXES*/

	

	-- Dummy for Proficient


    SELECT  *
          , CASE WHEN ProficincyLevelScore >= 3 THEN 1
                 ELSE 0
            END AS Above3
    INTO    #SBAC1
    FROM    #SBAC;




	
/* Calculate Averages different levels*/
	



	-- CT NETWORK-- 
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    INTO    #SBAC2
    FROM    #SBAC1
    GROUP BY TestSubject
    UNION ALL

	--CT GRADE--
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SBAC1
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL

	-- CT STATE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SBAC1
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL

	-- CT SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SBAC1
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL


	-- CT SCHOOL --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SBAC1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	
	-- CT STATE x SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SBAC1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	-- CT BY STATE x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SBAC1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL


	-- CT BY SCHOOL x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SBAC1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel;




/*Assign Metric IDs based on Test Subject, then drop test subject*/

    SELECT  CASE WHEN Test = 'ELA' THEN 'SBCE'
                 WHEN Test = 'Math' THEN 'SBCM'
            END AS Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , Test
          , GradeLevel
          , Actual
    INTO    #SBACFinal
    FROM    #SBAC2;




/* ----------------------------- END CT SBAC CODE----------------------------------------*/

/* ----------------------------- BEGIN PARCC CODE----------------------------------------*/
															
    SELECT  *
    INTO    #PARCC
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'PARCC' )
            AND SchoolYear = @CurrentYear
            AND TestScoreType = 'Test'
        
        
   															


	-- Dummy for Proficient 4 is Proficient for PARCC


    SELECT  *
          , CASE WHEN ProficincyLevelScore >= 4 THEN 1
                 ELSE 0
            END AS Above3
    INTO    #PARCC1
    FROM    #PARCC;
    



/* Calculate Averages different levels*/
	

	-- PARCC NETWORK-- 
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    INTO    #PARCC2
    FROM    #PARCC1
    GROUP BY TestSubject
    UNION ALL

	-- PARCC GRADE--
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #PARCC1
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL

	-- PARCC STATE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #PARCC1
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL

	-- PARCC SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #PARCC1
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL


	-- PARCC SCHOOL --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #PARCC1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	
	-- PARCC STATE x SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #PARCC1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	-- PARCC BY STATE x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #PARCC1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL


	-- PARCC BY SCHOOL x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #PARCC1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel;



/*Assign Metric IDs based on Test Subject, then drop test subject*/

    SELECT  CASE WHEN Test = 'ELA' THEN 'PRCE'
                 WHEN Test = 'Math' THEN 'PRCM'
            END AS Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , Test
          , GradeLevel
          , Actual
    INTO    #PARCCFinal
    FROM    #PARCC2;


	





/* ----------------------------- END PARCC CODE----------------------------------------*/
*//
/* ----------------------------- BEGIN MAP CODE----------------------------------------*/


																	
    SELECT  *
    INTO    #MAP
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'Survey with Goals' )
            AND SchoolYear = @CurrentYear
            AND TestScoreType = 'Test'
            AND TestSubject = 'Mathematics'
            AND TestPeriod = @MAPCycle
            AND gradelevel IN ( 'K', '1st', '2nd' );
																	 	



	-- Dummy for Proficient

    SELECT  *
          , CASE WHEN PercentileScore >= @MAPTarget THEN 1
                 ELSE 0
            END AS Above3
    INTO    #MAP1
    FROM    #MAP;


Select * from #MAP




	
/* Calculate Averages different levels*/
	


	-- MAP NETWORK-- 
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    INTO    #MAP2
    FROM    #MAP1
    GROUP BY TestSubject
    UNION ALL

	-- MAP GRADE--
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #MAP1
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL

	-- MAP STATE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #MAP1
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL

	-- MAP SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #MAP1
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL


	-- MAP SCHOOL --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #MAP1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	
	-- MAP STATE x SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #MAP1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	-- MAP BY STATE x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #MAP1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL


	-- MAP BY SCHOOL x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #MAP1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel;



/*Assign Metric IDs based on Test Subject, then drop test subject*/

    SELECT  'MPMA' AS Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , Test
          , GradeLevel
          , Actual
    INTO    #MAPFinal
    FROM    #MAP2;



/* ----------------------------- END MAP CODE----------------------------------------*/

/* ----------------------------- BEGIN STEP/F&P CODE----------------------------------------*/

																	-- Change School Year --
    SELECT  *
    INTO    #STEP
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'F&P', 'STEP' )
            AND SchoolYear = @CurrentYear
            AND TestScoreType = 'Test'
            AND TestScore IS NOT NULL
            AND gradelevel IN ( 'K', '1st', '2nd' )
            AND TestPeriod = @STEPCYCLE;
																	 -- Change School Year --	





		-- Dummy for Proficient and Advanced


    SELECT  *
          , CASE WHEN ProficiencyLevelCode >= 3 THEN 1
                 ELSE 0
            END AS Above3
          , CASE WHEN ProficiencyLevelCode = 4 THEN 1
                 ELSE 0
            END AS Above4
    INTO    #STEP1
    FROM    #STEP;


/* Calculate Averages different levels*/



	-- STEP NETWORK-- 
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
          , 'Proficient' AS [Type]
    INTO    #STEP2
    FROM    #STEP1
    GROUP BY TestSubject
    UNION ALL
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above4 AS FLOAT)) AS Actual
          , 'Advanced' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
    UNION ALL

	--STEP GRADE--
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
          , 'Proficient' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above4 AS FLOAT)) AS Actual
          , 'Advanced' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL

	-- STEP STATE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
          , 'Proficient' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above4 AS FLOAT)) AS Actual
          , 'Advanced' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL

	-- STEP SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
          , 'Proficient' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above4 AS FLOAT)) AS Actual
          , 'Advanced' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL


	-- STEP SCHOOL --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
          , 'Proficient' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above4 AS FLOAT)) AS Actual
          , 'Advanced' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	
	-- STEP STATE x SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
          , 'Proficient' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above4 AS FLOAT)) AS Actual
          , 'Advanced' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	-- STEP BY STATE x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
          , 'Proficient' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above4 AS FLOAT)) AS Actual
          , 'Advanced' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL



	-- STEP BY SCHOOL x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
          , 'Proficient' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above4 AS FLOAT)) AS Actual
          , 'Advanced' AS [Type]
    FROM    #STEP1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel;






/*Assign Metric IDs based on Test Subject, then drop test subject*/
    SELECT  CASE WHEN [Type] = 'Proficient' THEN 'STPP'
                 WHEN [Type] = 'Advanced' THEN 'STPA'
            END AS Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , Test
          , GradeLevel
          , Actual
    INTO    #STEPFinal
    FROM    #STEP2;




/* ----------------------------- END STEP/F&P CODE----------------------------------------*/


/* ----------------------------- BEGIN 8th Grade EOY IA (History/Science) CODE----------------------------------------*/
/*------------------------------- METRIC NEEDS TO BE UPDATED --------------------------------------------------------*/



																	
    SELECT  *
    INTO    #8Gr
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'IA' )
            AND SchoolYear = @CurrentYear
            AND TestScoreType = 'Test'
            AND TestSubject IN ( 'History', 'Science' )
            AND TestPeriod IN ( 'EOY' )
            AND gradelevel IN ( '8th' );
																	 	



	-- Dummy for Proficient WILL CHANGE!!!!


    SELECT  *
          , CASE WHEN PercentScore >= @8IATarget THEN 1
                 ELSE 0
            END AS Above3
    INTO    #8Gr1
    FROM    #8Gr;




	
/* Calculate Averages different levels*/
	



	
	-- 8th Grade Hist/Sci NETWORK-- 
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(PercentScore AS FLOAT)) AS Actual
    INTO    #8Gr2
    FROM    #8Gr1
    GROUP BY TestSubject
    UNION ALL

	-- 8th Grade Hist/Sci GRADE--
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(PercentScore AS FLOAT)) AS Actual
    FROM    #8Gr1
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL

	-- 8th Grade Hist/Sci STATE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(PercentScore AS FLOAT)) AS Actual
    FROM    #8Gr1
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL

	-- 8th Grade Hist/Sci SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(PercentScore AS FLOAT)) AS Actual
    FROM    #8Gr1
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL


	-- 8th Grade Hist/Sci SCHOOL --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(PercentScore AS FLOAT)) AS Actual
    FROM    #8Gr1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	
	-- 8th Grade Hist/Sci STATE x SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(PercentScore AS FLOAT)) AS Actual
    FROM    #8Gr1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	-- 8th Grade Hist/Sci BY STATE x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(PercentScore AS FLOAT)) AS Actual
    FROM    #8Gr1
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL


	-- 8th Grade Hist/Sci BY SCHOOL x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS [State]
          , gradelevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(PercentScore AS FLOAT)) AS Actual
    FROM    #8Gr1
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel;



/*Assign Metric IDs based on Test Subject, then drop test subject*/


    SELECT  CASE WHEN Test = 'History' THEN 'HIST'
                 WHEN Test = 'Science' THEN 'SCIE'
            END AS Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , Test
          , GradeLevel
          , Actual
    INTO    #8GrFinal
    FROM    #8Gr2;







/* ----------------------------- END 8th Grade EOY IA (History/Science) CODE----------------------------------------*/

/**
/* ----------------------------- BEGIN SATCODE----------------------------------------*/

/*OLD SAT Scores that NEED CONVERSION*/


																	
    SELECT  SchoolYear AS SchoolYear
          , TestDate AS TestDate
          , SystemStudentID AS SystemStudentID
          , 'Math' AS TestSubject
          , Fullname AS Fullname
          , gradelevel AS GradeLevel
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , TestScore AS Testscore
    INTO    #SATMath
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'SAT' )
            AND SchoolYear = @CurrentYear
            AND GradeLevel IN ( '11th', '12th' )
            AND TestScoreType = 'Test'
            AND TestSubject = 'Math'; 
																	


/*Sum Old CR and W*/


    SELECT  SchoolYear AS SchoolYear
          , TestDate AS TestDate
          , SystemStudentID AS SystemStudentID
          , 'CR + W' AS TestSubject
          , Fullname AS Fullname
          , gradelevel AS GradeLevel
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , SUM(TestScore) AS Testscore
    INTO    #SATCrW
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'SAT' )
            AND SchoolYear = @CurrentYear
            AND GradeLevel IN ( '11th', '12th' )
            AND TestScoreType = 'Test'
            AND TestSubject IN ( 'Critical Reading', 'Writing' )
    GROUP BY SchoolYear
          , TestDate
          , SystemStudentID
          , Fullname
          , GradeLevel
          , SchoolName
          , SchoolLevel
          , SchoolRegion;



/*Union Old Math and Old CR + W*/

    SELECT  *
    INTO    #SATOld
    FROM    ( SELECT    *
              FROM      #SATMath
              UNION
              SELECT    *
              FROM      #SATCrW
            ) a;

	
											 	
/* Convert OLD CR+W into NEW EBRW and OLD Math into New Math*/

	

    SELECT  SchoolYear AS SchoolYear
          , TestDate AS TestDate
          , SystemStudentID AS SystemStudentID
          , TestSubject AS TestSubject
          , Fullname AS Fullname
          , GradeLevel AS GradeLevel
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , Testscore AS TestScore
          , CASE
			/*FOR CR+W*/
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 400 THEN 200
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 410 THEN 210
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 420 THEN 220
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 430 THEN 230
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 440 THEN 240
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 450 THEN 260
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 460 THEN 270
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 470 THEN 280
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 480 THEN 290
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 490 THEN 300
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 500 THEN 310
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 510 THEN 310
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 520 THEN 320
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 530 THEN 320
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 540 THEN 330
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 550 THEN 330
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 560 THEN 330
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 570 THEN 340
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 580 THEN 340
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 590 THEN 350
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 600 THEN 350
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 610 THEN 360
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 620 THEN 360
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 630 THEN 360
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 640 THEN 370
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 650 THEN 370
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 660 THEN 380
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 670 THEN 380
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 680 THEN 390
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 690 THEN 390
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 700 THEN 400
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 710 THEN 400
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 720 THEN 410
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 730 THEN 410
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 740 THEN 420
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 750 THEN 420
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 760 THEN 430
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 770 THEN 430
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 780 THEN 440
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 790 THEN 440
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 800 THEN 450
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 810 THEN 450
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 820 THEN 460
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 830 THEN 460
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 840 THEN 470
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 850 THEN 480
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 860 THEN 480
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 870 THEN 490
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 880 THEN 490
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 890 THEN 500
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 900 THEN 500
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 910 THEN 510
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 920 THEN 510
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 930 THEN 520
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 940 THEN 530
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 950 THEN 530
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 960 THEN 540
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 970 THEN 540
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 980 THEN 550
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 990 THEN 550
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1000 THEN 560
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1010 THEN 560
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1020 THEN 570
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1030 THEN 570
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1040 THEN 580
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1050 THEN 580
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1060 THEN 590
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1070 THEN 590
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1080 THEN 600
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1090 THEN 600
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1100 THEN 610
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1110 THEN 610
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1120 THEN 620
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1130 THEN 620
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1140 THEN 630
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1150 THEN 630
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1160 THEN 640
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1170 THEN 640
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1180 THEN 650
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1190 THEN 650
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1200 THEN 650
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1210 THEN 660
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1220 THEN 660
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1230 THEN 670
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1240 THEN 670
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1250 THEN 680
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1260 THEN 680
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1270 THEN 680
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1280 THEN 690
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1290 THEN 690
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1300 THEN 700
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1310 THEN 700
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1320 THEN 700
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1330 THEN 710
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1340 THEN 710
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1350 THEN 710
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1360 THEN 720
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1370 THEN 720
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1380 THEN 730
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1390 THEN 730
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1400 THEN 730
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1410 THEN 740
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1420 THEN 740
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1430 THEN 740
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1440 THEN 750
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1450 THEN 750
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1460 THEN 750
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1470 THEN 760
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1480 THEN 760
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1490 THEN 760
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1500 THEN 770
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1510 THEN 770
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1520 THEN 770
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1530 THEN 780
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1540 THEN 780
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1550 THEN 780
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1560 THEN 790
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1570 THEN 790
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1580 THEN 800
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1590 THEN 800
                 WHEN TestSubject = 'CR + W'
                      AND Testscore = 1600 THEN 800

			/*FOR Math*/
                 WHEN TestSubject = 'Math'
                      AND Testscore = 200 THEN 200
                 WHEN TestSubject = 'Math'
                      AND Testscore = 210 THEN 220
                 WHEN TestSubject = 'Math'
                      AND Testscore = 220 THEN 230
                 WHEN TestSubject = 'Math'
                      AND Testscore = 230 THEN 250
                 WHEN TestSubject = 'Math'
                      AND Testscore = 240 THEN 260
                 WHEN TestSubject = 'Math'
                      AND Testscore = 250 THEN 280
                 WHEN TestSubject = 'Math'
                      AND Testscore = 260 THEN 300
                 WHEN TestSubject = 'Math'
                      AND Testscore = 270 THEN 310
                 WHEN TestSubject = 'Math'
                      AND Testscore = 280 THEN 330
                 WHEN TestSubject = 'Math'
                      AND Testscore = 290 THEN 340
                 WHEN TestSubject = 'Math'
                      AND Testscore = 300 THEN 350
                 WHEN TestSubject = 'Math'
                      AND Testscore = 310 THEN 360
                 WHEN TestSubject = 'Math'
                      AND Testscore = 320 THEN 360
                 WHEN TestSubject = 'Math'
                      AND Testscore = 330 THEN 370
                 WHEN TestSubject = 'Math'
                      AND Testscore = 340 THEN 380
                 WHEN TestSubject = 'Math'
                      AND Testscore = 350 THEN 390
                 WHEN TestSubject = 'Math'
                      AND Testscore = 360 THEN 400
                 WHEN TestSubject = 'Math'
                      AND Testscore = 370 THEN 410
                 WHEN TestSubject = 'Math'
                      AND Testscore = 380 THEN 420
                 WHEN TestSubject = 'Math'
                      AND Testscore = 390 THEN 430
                 WHEN TestSubject = 'Math'
                      AND Testscore = 400 THEN 440
                 WHEN TestSubject = 'Math'
                      AND Testscore = 410 THEN 450
                 WHEN TestSubject = 'Math'
                      AND Testscore = 420 THEN 460
                 WHEN TestSubject = 'Math'
                      AND Testscore = 430 THEN 470
                 WHEN TestSubject = 'Math'
                      AND Testscore = 440 THEN 480
                 WHEN TestSubject = 'Math'
                      AND Testscore = 450 THEN 490
                 WHEN TestSubject = 'Math'
                      AND Testscore = 460 THEN 500
                 WHEN TestSubject = 'Math'
                      AND Testscore = 470 THEN 510
                 WHEN TestSubject = 'Math'
                      AND Testscore = 480 THEN 510
                 WHEN TestSubject = 'Math'
                      AND Testscore = 490 THEN 520
                 WHEN TestSubject = 'Math'
                      AND Testscore = 500 THEN 530
                 WHEN TestSubject = 'Math'
                      AND Testscore = 510 THEN 540
                 WHEN TestSubject = 'Math'
                      AND Testscore = 520 THEN 550
                 WHEN TestSubject = 'Math'
                      AND Testscore = 530 THEN 560
                 WHEN TestSubject = 'Math'
                      AND Testscore = 540 THEN 570
                 WHEN TestSubject = 'Math'
                      AND Testscore = 550 THEN 570
                 WHEN TestSubject = 'Math'
                      AND Testscore = 560 THEN 580
                 WHEN TestSubject = 'Math'
                      AND Testscore = 570 THEN 590
                 WHEN TestSubject = 'Math'
                      AND Testscore = 580 THEN 600
                 WHEN TestSubject = 'Math'
                      AND Testscore = 590 THEN 610
                 WHEN TestSubject = 'Math'
                      AND Testscore = 600 THEN 620
                 WHEN TestSubject = 'Math'
                      AND Testscore = 610 THEN 630
                 WHEN TestSubject = 'Math'
                      AND Testscore = 620 THEN 640
                 WHEN TestSubject = 'Math'
                      AND Testscore = 630 THEN 650
                 WHEN TestSubject = 'Math'
                      AND Testscore = 640 THEN 660
                 WHEN TestSubject = 'Math'
                      AND Testscore = 650 THEN 670
                 WHEN TestSubject = 'Math'
                      AND Testscore = 660 THEN 690
                 WHEN TestSubject = 'Math'
                      AND Testscore = 670 THEN 700
                 WHEN TestSubject = 'Math'
                      AND Testscore = 680 THEN 710
                 WHEN TestSubject = 'Math'
                      AND Testscore = 690 THEN 720
                 WHEN TestSubject = 'Math'
                      AND Testscore = 700 THEN 730
                 WHEN TestSubject = 'Math'
                      AND Testscore = 710 THEN 740
                 WHEN TestSubject = 'Math'
                      AND Testscore = 720 THEN 750
                 WHEN TestSubject = 'Math'
                      AND Testscore = 730 THEN 760
                 WHEN TestSubject = 'Math'
                      AND Testscore = 740 THEN 760
                 WHEN TestSubject = 'Math'
                      AND Testscore = 750 THEN 770
                 WHEN TestSubject = 'Math'
                      AND Testscore = 760 THEN 780
                 WHEN TestSubject = 'Math'
                      AND Testscore = 770 THEN 780
                 WHEN TestSubject = 'Math'
                      AND Testscore = 780 THEN 790
                 WHEN TestSubject = 'Math'
                      AND Testscore = 790 THEN 800
                 WHEN TestSubject = 'Math'
                      AND Testscore = 800 THEN 800
            END AS NewTestScore
    INTO    #SATOldConvert
    FROM    #SATOld;

	

    SELECT  SchoolYear AS SchoolYear
          , TestDate AS TestDate
          , SystemStudentID AS SystemStudentID
          , CASE WHEN TestSubject = 'CR + W'
                 THEN 'Evidence-Based Reading And Writing Section'
                 WHEN TestSubject = 'Math' THEN 'Math Section'
            END AS TestSubject
          , Fullname AS Fullname
          , GradeLevel AS GradeLevel
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , NewTestScore AS TestScore
    INTO    #SATOldFinal
    FROM    #SATOldConvert;
				




/*NEW SAT Scores that dont need to be converted*/



    SELECT  SchoolYear AS SchoolYear
          , TestDate AS TestDate
          , SystemStudentID AS SystemStudentID
          , TestSubject AS TestSubject
          , Fullname AS Fullname
          , gradelevel AS GradeLevel
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , TestScore AS Testscore
    INTO    #SATNew
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'SAT' )
            AND SchoolYear = @CurrentYear
            AND GradeLevel IN ( '11th', '12th' )
            AND TestScoreType = 'Section'
            AND TestSubject IN ( 'Evidence-Based Reading And Writing Section',
                                 'Math Section' );





		/* Union Old Converted and New to find max per subject.  Sum the max to get the metric we need*/
		
			
    SELECT  SchoolYear AS SchoolYear
          , SystemStudentID AS SystemStudentID
          , TestSubject AS TestSubject
          , Fullname AS Fullname
          , GradeLevel AS GradeLevel
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , MAX(TestScore) AS Testscore
    INTO    #SATOldNew
    FROM    ( SELECT    *
              FROM      #SATOldFinal
              UNION
              SELECT    *
              FROM      #SATNew
            ) a
    GROUP BY SchoolYear
          , SystemStudentID
          , TestSubject
          , Fullname
          , GradeLevel
          , SchoolName
          , SchoolLevel
          , SchoolRegion;



		
		/*Sum max*/

			
    SELECT  SchoolYear AS SchoolYear
          , SystemStudentID AS SystemStudentID
          , 'EBRW + Math' AS TestSubject
          , Fullname AS Fullname
          , GradeLevel AS GradeLevel
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , SUM(Testscore) AS Testscore
    INTO    #SATMax
    FROM    #SATOldNew
    GROUP BY SchoolYear
          , SystemStudentID
          , Fullname
          , GradeLevel
          , SchoolName
          , SchoolLevel
          , SchoolRegion;


/*SAT ESSAY*/

 --  Add test components -- 
    SELECT  SchoolYear AS SchoolYear
          , TestDate AS TestDate
          , SystemStudentID AS SystemStudentID
          , 'SAT Essay' AS TestSubject
          , Fullname AS Fullname
          , gradelevel AS GradeLevel
          , SchoolName AS SchoolName
          , schoollevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , SUM(TestScore) AS Testscore
    INTO    #SATEssay
    FROM    #AllAssessments
    WHERE   TestSubType IN ( 'SAT' )
            AND SchoolYear = @CurrentYear
            AND GradeLevel IN ( '11th', '12th' )
            AND TestScoreType = 'Subscore'
            AND TestName IN ( 'SAT Essay Analysis', 'SAT Essay Writing',
                              'SAT Essay Reading' )
    GROUP BY SchoolYear
          , TestDate
          , SystemStudentID
          , Fullname
          , GradeLevel
          , SchoolName
          , SchoolLevel
          , SchoolRegion;



-- Find Max Essay Across All Test Periods -- 

    SELECT  SchoolYear AS SchoolYear
          , SystemStudentID AS SystemStudentID
          , 'SAT Essay' AS TestSubject
          , Fullname AS Fullname
          , GradeLevel AS GradeLevel
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS SchoolRegion
          , MAX(Testscore) AS Testscore
    INTO    #SATEssayMax
    FROM    #SATEssay
    GROUP BY SchoolYear
          , SystemStudentID
          , Fullname
          , GradeLevel
          , SchoolName
          , SchoolLevel
          , SchoolRegion;



/* Union SAT Max and SAT Essay Max and apply Target Logic*/

-- SAT ESSAY TARGET IS A PLACEHOLDER -- 


    SELECT  *
          , CASE WHEN TestSubject = 'SAT Essay'
                      AND Testscore >= @SATEssayTarget THEN 1
                 WHEN TestSubject = 'EBRW + Math'
                      AND Testscore >= @SATTarget THEN 1
                 ELSE 0
            END AS Above3
    INTO    #SAT
    FROM    ( SELECT    *
              FROM      #SATMax
              UNION
              SELECT    *
              FROM      #SATEssayMax
            ) a;



	

/* Calculate Averages different levels*/
	



	
	-- SAT NETWORK-- 
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    INTO    #SAT1
    FROM    #SAT
    GROUP BY TestSubject
    UNION ALL

	-- SAT GRADE--
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , SchoolLevel AS SchoolLevel
          , 'All' AS [State]
          , GradeLevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SAT
    GROUP BY TestSubject
          , SchoolLevel
          , GradeLevel
    UNION ALL

	-- SAT STATE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , 'All' AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SAT
    GROUP BY TestSubject
          , SchoolRegion
    UNION ALL

	-- SAT SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , SchoolLevel AS SchoolLevel
          , 'All' AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SAT
    GROUP BY TestSubject
          , SchoolLevel
    UNION ALL


	-- SAT SCHOOL --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SAT
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	
	-- SAT STATE x SCHOOL LEVEL --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS [State]
          , 'All' AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SAT
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
    UNION ALL

	-- SAT BY STATE x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , 'All' AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS [State]
          , GradeLevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SAT
    GROUP BY TestSubject
          , SchoolLevel
          , SchoolRegion
          , GradeLevel
    UNION ALL


	-- SAT BY SCHOOL x GRADE --
    SELECT  @KPIMonth AS KPIMonth
          , SchoolName AS SchoolName
          , SchoolLevel AS SchoolLevel
          , SchoolRegion AS [State]
          , GradeLevel AS GradeLevel
          , TestSubject AS Test
          , AVG(CAST(Above3 AS FLOAT)) AS Actual
    FROM    #SAT
    GROUP BY TestSubject
          , SchoolName
          , SchoolLevel
          , SchoolRegion
          , GradeLevel;



/*Assign Metric IDs based on Test Subject, then drop test subject*/


    SELECT  CASE WHEN Test = 'EBRW + Math' THEN 'SATA'
                 WHEN Test = 'SAT Essay' THEN 'SATB'
            END AS Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , Test
          , GradeLevel
          , Actual
    INTO    #SATFinal
    FROM    #SAT1;


**/


/* ----------------------------- END SAT CODE----------------------------------------*/

/* --------------UNION ALL SUB DATASETS -----------------------------*/


    SELECT  Code
          , KPIMonth
          , SchoolName
          , SchoolLevel
          , [State]
          , GradeLevel
          , Actual
    INTO    #EOYFINAL
    FROM    ( 
              SELECT    *
              FROM      #MAPFinal
              UNION
              SELECT    *
              FROM      #STEPFinal
              UNION
              SELECT    *
              FROM      #8GrFinal
              
            ) a;
            
            
       
     
			  
    
    
    /*Commenting out for now -- adrian to run
    INSERT  INTO kpi.EOYAcademicCode
            ( Code
            , KPIMonth as EOYRun
            , SchoolName
            , SchoolLevel
            , [State]
            , Gradelevel
            , Actual
			
            )
            SELECT  Code
                  , KPIMonth as EOYRun
                  , SchoolName
                  , SchoolLevel
                  , [State]
                  , GradeLevel
                  , Actual
            FROM    #EOYFINAL*/

    DROP TABLE #AP;
    DROP TABLE #AP0;
    DROP TABLE #AP1;
    DROP TABLE #AP2;
    DROP TABLE #AP3;
    DROP TABLE #APMathMax;
    DROP TABLE #APSciMax;
    DROP TABLE #APFinal;
    DROP TABLE #APOther;
    DROP TABLE #AllAssessments;
    DROP TABLE #NYS;
    DROP TABLE #NYS1;
    DROP TABLE #NYS2;
    DROP TABLE #NYSFinal;
    DROP TABLE #SBAC;
    DROP TABLE #SBAC1;
    DROP TABLE #SBAC2;
    DROP TABLE #SBACFinal;
    DROP TABLE #PARCC;
    DROP TABLE #PARCC1;
    DROP TABLE #PARCC2;
    DROP TABLE #PARCCFinal;
    DROP TABLE #MAP;
    DROP TABLE #MAP1;
    DROP TABLE #MAP2;
    DROP TABLE #MAPFinal;
    DROP TABLE #STEP;
    DROP TABLE #STEP1;
    DROP TABLE #STEP2;
    DROP TABLE #STEPFinal;
    DROP TABLE #8Gr;
    DROP TABLE #8Gr1;
    DROP TABLE #8Gr2;
    DROP TABLE #8GrFinal;
    DROP TABLE #SATMath;
    DROP TABLE #SATCrW;
    DROP TABLE #SATOld;
    DROP TABLE #SATOldConvert;
    DROP TABLE #SATOldFinal;
    DROP TABLE #SATNew;
    DROP TABLE #SATOldNew;
    DROP TABLE #SATMax;
    DROP TABLE #SATEssay;
    DROP TABLE #SATEssayMax;
    DROP TABLE #SAT;
    DROP TABLE #SAT1;
    DROP TABLE #SATFinal;
   --DROP TABLE #EOYFINAL;