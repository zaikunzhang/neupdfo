        !COMPILER-GENERATED INTERFACE MODULE: Tue Jun 30 00:56:18 2020
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE NEWUOA__genmod
          INTERFACE 
            SUBROUTINE NEWUOA(N,NPT,X,RHOBEG,RHOEND,IPRINT,MAXFUN,F,INFO&
     &,FTARGET)
              INTEGER(KIND=4), INTENT(IN) :: N
              INTEGER(KIND=4), INTENT(IN) :: NPT
              REAL(KIND=8), INTENT(INOUT) :: X(N)
              REAL(KIND=8), INTENT(IN) :: RHOBEG
              REAL(KIND=8), INTENT(IN) :: RHOEND
              INTEGER(KIND=4), INTENT(IN) :: IPRINT
              INTEGER(KIND=4), INTENT(IN) :: MAXFUN
              REAL(KIND=8), INTENT(OUT) :: F
              INTEGER(KIND=4), INTENT(OUT) :: INFO
              REAL(KIND=8), INTENT(IN) :: FTARGET
            END SUBROUTINE NEWUOA
          END INTERFACE 
        END MODULE NEWUOA__genmod
