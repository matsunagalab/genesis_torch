!C
!C     FFTE: A FAST FOURIER TRANSFORM PACKAGE
!C
!C     (C) COPYRIGHT SOFTWARE, 2000-2004, 2008-2011, ALL RIGHTS RESERVED
!C                BY
!C         DAISUKE TAKAHASHI
!C         FACULTY OF ENGINEERING, INFORMATION AND SYSTEMS
!C         UNIVERSITY OF TSUKUBA
!C         1-1-1 TENNODAI, TSUKUBA, IBARAKI 305-8573, JAPAN
!C         E-MAIL: daisuke@cs.tsukuba.ac.jp
!C
!C
!C     3-D COMPLEX-TO-REAL FFT ROUTINE
!C
!C     FORTRAN77 SOURCE PROGRAM
!C
!C     CALL ZDFFT3D(A,NX,NY,NZ,IOPT,B)
!C
!C     A(NX/2+1,NY,NZ) IS COMPLEX INPUT VECTOR (COMPLEX(WP))
!C     A(NX,NY,NZ) IS REAL OUTPUT VECTOR (REAL(WP))
!C     B(NX/2+1,NY,NZ) IS WORK VECTOR (COMPLEX(WP))
!C     NX IS THE LENGTH OF THE TRANSFORMS IN THE X-DIRECTION (INTEGER*4)
!C     NY IS THE LENGTH OF THE TRANSFORMS IN THE Y-DIRECTION (INTEGER*4)
!C     NZ IS THE LENGTH OF THE TRANSFORMS IN THE Z-DIRECTION (INTEGER*4)
!C       ------------------------------------
!C         NX = (2**IP) * (3**IQ) * (5**IR)
!C         NY = (2**JP) * (3**JQ) * (5**JR)
!C         NZ = (2**KP) * (3**KQ) * (5**KR)
!C       ------------------------------------
!C     IOPT = 0 FOR INITIALIZING THE COEFFICIENTS (INTEGER*4)
!C          = +1 FOR INVERSE TRANSFORM
!C
!C     WRITTEN BY DAISUKE TAKAHASHI
!C
#ifdef HAVE_CONFIG_H
#include "../config.h"
#endif

#if !defined(_SINGLE) && !defined(_MIXED)

      SUBROUTINE ZDFFT3D(A,NX,NY,NZ,IOPT,B)
      USE CONSTANTS_MOD
      IMPLICIT REAL(WP) (A-H,O-Z)
      INCLUDE 'ffte_param.h'
      COMPLEX(WP) A(*),B(*)
      COMPLEX(WP) C((NDA3+NP)*NBLK),D(NDA3)
      COMPLEX(WP) WX(NDA3),WY(NDA3),WZ(NDA3)
      DIMENSION LNX(3),LNY(3),LNZ(3)
      SAVE WX,WY,WZ
!C
      CALL FACTOR(NX,LNX)
      CALL FACTOR(NY,LNY)
      CALL FACTOR(NZ,LNZ)
!C
      IF (IOPT .EQ. 0) THEN
        CALL SETTBL(WX,NX)
        CALL SETTBL(WY,NY)
        CALL SETTBL(WZ,NZ)
        RETURN
      END IF
!C
!$OMP PARALLEL PRIVATE(C,D)
      CALL ZDFFT3D0(A,A,B,C,C,C,D,WX,WY,WZ,NX,NY,NZ,LNX,LNY,LNZ)
!$OMP END PARALLEL
      RETURN
      END
      SUBROUTINE ZDFFT3D0(A,DA,B,CX,CY,CZ,D,WX,WY,WZ,NX,NY,NZ, &
                         LNX,LNY,LNZ)
      USE CONSTANTS_MOD
      IMPLICIT REAL(WP) (A-H,O-Z)
      INCLUDE 'ffte_param.h'
      COMPLEX(WP) A(NX/2+1,NY,*),B(NX/2+1,NY,*)
      COMPLEX(WP) CX(*),CY(NY+NP,*),CZ(NZ+NP,*),D(*)
      COMPLEX(WP) WX(*),WY(*),WZ(*)
      COMPLEX(WP) TEMP
      DIMENSION DA(NX,NY,*)
      DIMENSION LNX(*),LNY(*),LNZ(*)
!C
      DN=1.0D0/(DBLE(NX)*DBLE(NY)*DBLE(NZ))
!C
!$OMP DO
      DO 70 J=1,NY
        DO 60 II=1,NX/2+1,NBLK
          DO 20 I=II,MIN0(II+NBLK-1,NX/2+1)
!!DIR$ VECTOR ALIGNED
            DO 10 K=1,NZ
              CZ(K,I-II+1)=DCONJG(A(I,J,K))
   10       CONTINUE
   20     CONTINUE
          DO 30 I=II,MIN0(II+NBLK-1,NX/2+1)
            CALL FFT235(CZ(1,I-II+1),D,WZ,NZ,LNZ)
   30     CONTINUE
          DO 50 K=1,NZ
!!DIR$ VECTOR ALIGNED
            DO 40 I=II,MIN0(II+NBLK-1,NX/2+1)
              B(I,J,K)=CZ(K,I-II+1)
   40       CONTINUE
   50     CONTINUE
   60   CONTINUE
   70 CONTINUE
!$OMP DO PRIVATE(TEMP)
      DO 220 K=1,NZ
        DO 130 II=1,NX/2+1,NBLK
          DO 90 I=II,MIN0(II+NBLK-1,NX/2+1)
!!DIR$ VECTOR ALIGNED
            DO 80 J=1,NY
              CY(J,I-II+1)=B(I,J,K)
   80       CONTINUE
   90     CONTINUE
          DO 100 I=II,MIN0(II+NBLK-1,NX/2+1)
            CALL FFT235(CY(1,I-II+1),D,WY,NY,LNY)
  100     CONTINUE
          DO 120 J=1,NY
!!DIR$ VECTOR ALIGNED
            DO 110 I=II,MIN0(II+NBLK-1,NX/2+1)
              B(I,J,K)=CY(J,I-II+1)
  110       CONTINUE
  120     CONTINUE
  130   CONTINUE
        IF (MOD(NY,2) .EQ. 0) THEN
          DO 160 J=1,NY,2
            CX(1)=DCMPLX(DBLE(B(1,J,K)),DBLE(B(1,J+1,K)))
!!DIR$ VECTOR ALIGNED
            DO 140 I=2,NX/2+1
              TEMP=(0.0D0,1.0D0)*B(I,J+1,K)
              CX(I)=B(I,J,K)+TEMP
              CX(NX-I+2)=DCONJG(B(I,J,K)-TEMP)
  140       CONTINUE
            CALL FFT235(CX,D,WX,NX,LNX)
            DO 150 I=1,NX
              DA(I,J,K)=DBLE(CX(I))*DN
              DA(I,J+1,K)=DIMAG(CX(I))*DN
  150       CONTINUE
  160     CONTINUE
        ELSE
          DO 190 J=1,NY-1,2
            CX(1)=DCMPLX(DBLE(B(1,J,K)),DBLE(B(1,J+1,K)))
!!DIR$ VECTOR ALIGNED
            DO 170 I=2,NX/2+1
              TEMP=(0.0D0,1.0D0)*B(I,J+1,K)
              CX(I)=B(I,J,K)+TEMP
              CX(NX-I+2)=DCONJG(B(I,J,K)-TEMP)
  170       CONTINUE
            CALL FFT235(CX,D,WX,NX,LNX)
            DO 180 I=1,NX
              DA(I,J,K)=DBLE(CX(I))*DN
              DA(I,J+1,K)=DIMAG(CX(I))*DN
  180       CONTINUE
  190     CONTINUE
          CX(1)=DCMPLX(DBLE(B(1,NY,K)),0.0D0)
!!DIR$ VECTOR ALIGNED
          DO 200 I=2,NX/2+1
            CX(I)=B(I,NY,K)
            CX(NX-I+2)=DCONJG(B(I,NY,K))
  200     CONTINUE
          CALL FFT235(CX,D,WX,NX,LNX)
          DO 210 I=1,NX
            DA(I,NY,K)=DBLE(CX(I))*DN
  210     CONTINUE
        END IF
  220 CONTINUE
      RETURN
      END
#endif
