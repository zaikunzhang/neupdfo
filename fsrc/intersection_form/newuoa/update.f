!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! This is the intersection-form version of update.f90.
! The file is generated automatically and is NOT intended to be readable.
!
! In the intersection form, each continued line has an ampersand at column
! 73, and each continuation line has an ampersand at column 6. A Fortran
! file in such a form can be compiled both as fixed form and as free form.
!
! See http://fortranwiki.org/fortran/show/Continuation+lines for details.
!
! Generated using the interform.m script by Zaikun Zhang (www.zhangzk.net)
! on 14-Jun-2021.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


! UPDATE_MOD is a module providing subroutines concerning the update of
! IDZ, BMAT, ZMAT, GQ, HQ, and PQ when XPT(:, KNEW) is replaced by XNEW.
!
! Coded by Zaikun Zhang in July 2020 based on Powell's Fortran 77 code
! and the NEWUOA paper.
!
! Last Modified: Saturday, May 22, 2021 PM04:18:05

      module update_mod

      implicit none
      private
      public :: updateh, updateq, tryqalt


      contains


      subroutine updateh(knew, beta, vlag_in, idz, bmat, zmat)
! UPDATE updates arrays BMAT and ZMAT together with IDZ, in order
! to replace the interpolation point XPT(:, KNEW) by XNEW. On entry,
! VLAG_IN contains the components of the vector THETA*WCHECK + e_b
! of the updating formula (6.11) in the NEWUOA paper, and BETA
! holds the value of the parameter that has this name. VLAG_IN and BETA
! contains information about XNEW, because they are calculated according
! to D = XNEW - XOPT.
!
! See Section 4 of the NEWUOA paper.

! Generic modules
      use consts_mod, only : RP, IK, ONE, ZERO, DEBUGGING, SRNLEN
      use debug_mod, only : errstop, verisize
      use lina_mod, only : grota, r2update, symmetrize

      implicit none

! Inputs
      integer(IK), intent(in) :: knew
      real(RP), intent(in) :: beta
      real(RP), intent(in) :: vlag_in(:) ! VLAG_IN(NPT + N)

! In-outputs
      integer(IK), intent(inout) :: idz
      real(RP), intent(inout) :: bmat(:, :) ! BMAT(N, NPT + N)
      real(RP), intent(inout) :: zmat(:, :) ! ZMAT(NPT, NPT - N - 1)

! Local variables
      integer(IK) :: j
      integer(IK) :: ja
      integer(IK) :: jb
      integer(IK) :: jl
      integer(IK) :: n
      integer(IK) :: npt
      real(RP) :: alpha
      real(RP) :: denom
      real(RP) :: scala
      real(RP) :: scalb
      real(RP) :: sqrtdn
      real(RP) :: tau
      real(RP) :: tausq
      real(RP) :: temp
      real(RP) :: tempa
      real(RP) :: tempb
      real(RP) :: v1(size(bmat, 1))
      real(RP) :: v2(size(bmat, 1))
      real(RP) :: vlag(size(vlag_in)) ! Copy of VLAG_IN
      real(RP) :: w(size(vlag_in))
      real(RP) :: ztemp(size(zmat, 1))
      logical :: reduce_idz
      character(len=SRNLEN), parameter :: srname = 'UPDATEH'


! Get and verify the sizes.
      n = int(size(bmat, 1), kind(n))
      npt = int(size(bmat, 2), kind(npt)) - n

      if (DEBUGGING) then
          if (n == 0 .or. npt < n + 2) then
              call errstop(srname, 'SIZE(BMAT) is invalid')
          end if
          call verisize(zmat, npt, int(npt - n - 1, kind(n)))
          call verisize(vlag_in, npt + n)
      end if

      vlag = vlag_in ! VLAG_IN is INTENT(IN) and cannot be revised.

! Apply the rotations that put zeros in the KNEW-th row of ZMAT.
! A Givens rotation will be multiplied to ZMAT from the left so
! ZMAT(KNEW, JL) becomes SQRT(ZMAT(KNEW, JL)^2 + ZMAT(KNEW, J)) and
! ZMAT(KNEW, J) becomes 0.
      jl = 1 ! For J = 2, ..., IDZ - 1, set JL = 1.
      do j = 2, int(idz - 1, kind(j))
          call grota(zmat, jl, j, knew)
      end do
      if (idz <= npt - n - 1) then
          jl = idz ! For J = IDZ + 1, ..., NPT - N - 1, set JL = IDZ.
      end if
      do j = int(idz + 1, kind(j)), int(npt - n - 1, kind(j))
          call grota(zmat, jl, j, knew)
      end do

! JL plays an important role below. Its value is determined by the
! current (i.e., unupdated) value of IDZ. IDZ is an integer in
! {1, ..., NPT - N} such that s_j = -1 for j < IDZ while s_j = 1
! for j >= IDZ in the factorization of Omega. See (3.17), (4.16)
! of the NEWUOA paper.
!
! For the value of JL, there are two possibilities:
! 1. JL = 1 iff IDZ = 1 or IDZ = NPT - N.
! 1.1. IDZ = 1 means that
! Omega = sum_{J=1}^{NPT-N-1} ZMAT(:, J)*ZMAT(:, J)' ;
! 1.2. IDZ = NPT - N means that
! Omega = - sum_{J=1}^{NPT-N-1} ZMAT(:, J)*ZMAT(:, J)' ;
! 2. JL = IDZ > 1 iff 2 <= IDZ <= NPT - N - 1.

! Put the first NPT components of the KNEW-th column of HLAG into
! W, and calculate the parameters of the updating formula.
      tempa = zmat(knew, 1)
      if (idz >= 2) then
          tempa = -tempa
      end if

      w(1:npt) = tempa * zmat(:, 1)
      if (jl > 1) then
          tempb = zmat(knew, jl)
          w(1:npt) = w(1:npt) + tempb * zmat(:, jl)
      end if

      alpha = w(knew)
      tau = vlag(knew)
      tausq = tau * tau
      denom = alpha * beta + tausq
! After the following line, VLAG = Hw - e_t in the NEWUOA paper.
      vlag(knew) = vlag(knew) - ONE
      sqrtdn = sqrt(abs(denom))

! Complete the updating of ZMAT when there is only one nonzero
! element in the KNEW-th row of the new matrix ZMAT, but, if
! IFLAG is set to one, then the first column of ZMAT will be
! exchanged with another one later.
      reduce_idz = .false.
      if (jl == 1) then
! There is only one nonzero in ZMAT(KNEW, :) after the
! rotation. This is the normal case, because IDZ is 1 in
! precise arithmetic.
!------------------------------------------------------------!
! Up to now, TEMPA = ZMAT(KNEW, 1) if IDZ = 1 and
! TEMPA = -ZMAT(KNEW, 1) if IDZ >= 2. However, according to
! (4.18) of the NEWUOA paper, TEMPB should always be
! ZMAT(KNEW, 1)/sqrtdn regardless of IDZ. Therefore, the
! following definition of TEMPB is inconsist with (4.18). This
! is probably a BUG. See also Lemma 4 and (5.13) of Powell's
! paper "On updating the inverse of a KKT matrix". However,
! the inconsistency is hardly observable in practice, because
! JL = 1 implies IDZ = 1 in precise arithmetic.
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++!
!tempb = tempa/sqrtdn
!tempa = tau/sqrtdn
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++!
! Here is the corrected version (only TEMPB is changed).
          tempa = tau / sqrtdn
          tempb = zmat(knew, 1) / sqrtdn
!------------------------------------------------------------!

          zmat(:, 1) = tempa * zmat(:, 1) - tempb * vlag(1:npt)

!------------------------------------------------------------!
! The following six lines by Powell are obviously problematic
! --- TEMP is always nonnegative.  According to (4.18) of the
! NEWUOA paper, the "TEMP < ZERO" and "TEMP >= ZERO" below
! should be both revised to "DENOM < ZERO". See also the
! corresponding part of the LINCOA code. Note that the NEAUOA
! paper uses SIGMA to denote DENOM. Check also Lemma 4 and
! (5.13) of Powell's paper "On updating the inverse of a KKT
! matrix". It seems that the BOBYQA code does not have this
! part --- it does not have IDZ at all (why?). Anyway, these
! lines are not invoked very often in practice, because IDZ
! should always be 1 in precise arithmetic.
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++!
!if (idz == 1 .and. sqrtdn < ZERO) then
!    idz = 2
!end if
!if (idz >= 2 .and. sqrtdn >= ZERO) then
!    reduce_idz = .true.
!end if
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++!
! This is the corrected version. It copies precisely the
! corresponding part of the LINCOA code.
          if (denom < ZERO) then
              if (idz == 1) then
! This is the first place (out of two) where IDZ is
! increased. Note that IDZ = 2 <= NPT-N after the update.
                  idz = 2
              else
! This is the first place (out of two) where IDZ is
! decreased (by 1). Since IDZ >= 2 in this case, we have
! IDZ >= 1 after the update.
                  reduce_idz = .true.
              end if
          end if
!------------------------------------------------------------!
      else
! Complete the updating of ZMAT in the alternative case.
! There are two nonzeros in ZMAT(KNEW, :) after the rotation.
          ja = 1
          if (beta >= ZERO) then
              ja = jl
          end if
          jb = int(jl + 1 - ja, kind(jb))
          temp = zmat(knew, jb) / denom
          tempa = temp * beta
          tempb = temp * tau
          temp = zmat(knew, ja)
          scala = ONE / sqrt(abs(beta) * temp * temp + tausq)
          scalb = scala * sqrtdn
          zmat(:, ja) = scala * (tau * zmat(:, ja) - temp * vlag(1:npt))
          zmat(:, jb) = scalb * (zmat(:, jb) - tempa * w(1:npt) - tempb &
     &* vlag(1:npt))
! If and only if DENOM <= 0, IDZ will be revised according
! to the sign of BETA. See (4.19)--(4.20) of the NEWUOA paper.
          if (denom <= ZERO) then
              if (beta < ZERO) then
! This is the second place (out of two) where IDZ is
! increased. Since JL = IDZ <= NPT-N-1 in this case,
! we have IDZ <= NPT-N after the update.
                  idz = int(idz + 1, kind(idz))
              end if
              if (beta >= ZERO) then
! This is the second place (out of two) where IDZ is
! decreased (by 1). Since IDZ >= 2 in this case, we have
! IDZ >= 1 after the update.
                  reduce_idz = .true.
              end if
          end if
      end if

! IDZ is reduced in the following case, and usually the first
! column of ZMAT is exchanged with a later one.
      if (reduce_idz) then
          idz = int(idz - 1, kind(idz))
          if (idz > 1) then
              ztemp = zmat(:, 1)
              zmat(:, 1) = zmat(:, idz)
              zmat(:, idz) = ztemp
          end if
      end if

! Finally, update the matrix BMAT.
      w(npt + 1:npt + n) = bmat(:, knew)
      v1 = (alpha * vlag(npt + 1:npt + n) - tau * w(npt + 1:npt + n)) / &
     &denom
      v2 = (-beta * w(npt + 1:npt + n) - tau * vlag(npt + 1:npt + n)) / &
     &denom

      call r2update(bmat, ONE, v1, vlag, ONE, v2, w)
! In floating-point arithmetic, the update above does not guarante
! BMAT(:, NPT+1 : NPT+N) to be symmetric. Symmetrization needed.
      call symmetrize(bmat(:, npt + 1:npt + n))

      end subroutine updateh


      subroutine updateq(idz, knew, bmatknew, fqdiff, zmat, xptknew, gq,&
     & hq, pq)
! UPDATEQ updates GQ, HQ, and PQ when XPT(:, KNEW) is replaced by XNEW.
! See Section 4 of the NEWUOA paper.

! Generic modules
      use consts_mod, only : RP, IK, ZERO, DEBUGGING, SRNLEN
      use debug_mod, only : errstop, verisize
      use lina_mod, only : r1update, Ax_plus_y

      implicit none

! Inputs
      integer(IK), intent(in) :: idz
      integer(IK), intent(in) :: knew
      real(RP), intent(in) :: bmatknew(:) ! BMATKNEW(N)
! fqdiff = [f(xnew) - f(xopt)] - [q(xnew) - q(xopt)] = moderr
      real(RP), intent(in) :: fqdiff
      real(RP), intent(in) :: zmat(:, :) ! ZMAT(NPT, NPT - N - 1)
      real(RP), intent(in) :: xptknew(:) ! XPTKNEW(N)

! In-outputs
      real(RP), intent(inout) :: gq(:) ! GQ(N)
      real(RP), intent(inout) :: hq(:, :)! HQ(N, N)
      real(RP), intent(inout) :: pq(:) ! PQ(NPT)

! Local variables
      integer(IK) :: n
      integer(IK) :: npt
      real(RP) :: fqdz(size(zmat, 2))
      character(len=SRNLEN), parameter :: srname = 'UPDATEQ'


! Get and verify the sizes.
      n = int(size(gq), kind(n))
      npt = int(size(pq), kind(npt))

      if (DEBUGGING) then
          if (n == 0 .or. npt < n + 2) then
              call errstop(srname, 'SIZE(GQ) or SIZE(PQ) is invalid')
          end if
          call verisize(zmat, npt, int(npt - n - 1, kind(n)))
          call verisize(xptknew, n)
          call verisize(bmatknew, n)
          call verisize(hq, n, n)
      end if

!----------------------------------------------------------------!
! Implement R1UPDATE properly so that it ensures HQ is symmetric.
      call r1update(hq, pq(knew), xptknew)
!----------------------------------------------------------------!

! Update the implicit part of second derivatives.
      fqdz = fqdiff * zmat(knew, :)
      fqdz(1:idz - 1) = -fqdz(1:idz - 1)
      pq(knew) = ZERO
!----------------------------------------------------------------!
!pq = pq + matprod(zmat, fqdz) !---------------------------------!
      pq = Ax_plus_y(zmat, fqdz, pq)
!----------------------------------------------------------------!

! Update the gradient.
      gq = gq + fqdiff * bmatknew

      end subroutine updateq


      subroutine tryqalt(idz, fval, ratio, smat, zmat, itest, gq, hq, pq&
     &)
! TRYQALT tests whether to replace Q by the alternative model,
! namely the model that minimizes the F-norm of the Hessian
! subject to the interpolation conditions. It does the replacement
! when certain criteria are satisfied (i.e., when ITEST = 3).
! Note that SMAT = BMAT(:, 1:NPT)
!
! See Section 8 of the NEWUOA paper.

! Generic modules
      use consts_mod, only : RP, IK, ZERO, DEBUGGING, SRNLEN
      use debug_mod, only : errstop, verisize
      use lina_mod, only : inprod, matprod

      implicit none

! Inputs
      integer(IK), intent(in) :: idz
      real(RP), intent(in) :: fval(:) ! FVAL(NPT)
      real(RP), intent(in) :: ratio
      real(RP), intent(in) :: smat(:, :) ! SMAT(N, NPT)
      real(RP), intent(in) :: zmat(:, :) ! ZMAT(NPT, NPT-N-!)

! In-output
      integer(IK), intent(inout) :: itest
      real(RP), intent(inout) :: gq(:) ! GQ(N)
      real(RP), intent(inout) :: hq(:, :) ! HQ(N, N)
      real(RP), intent(inout) :: pq(:) ! PQ(NPT)
! N.B.:
! GQ, HQ, and PQ should be INTENT(INOUT) instead of INTENT(OUT).
! According to the Fortran 2018 standard, an INTENT(OUT) dummy
! argument becomes undefined on invocation of the procedure.
! Therefore, if the procedure does not define such an argument,
! its value becomes undefined, which is the case for HQ and PQ
! when ITEST < 3 at exit. In addition, the information in GQ is
! needed for definining ITEST, so it must be INTENT(INOUT).

! Local variables
      integer(IK) :: n
      integer(IK) :: npt
      real(RP) :: fz(size(zmat, 2))
      real(RP) :: galt(size(gq))
      character(len=SRNLEN), parameter :: srname = 'TRYQALT'


! Get and verify the sizes.
      n = int(size(gq), kind(n))
      npt = int(size(pq), kind(npt))

      if (DEBUGGING) then
          if (n == 0 .or. npt < n + 2) then
              call errstop(srname, 'SIZE(GQ) or SIZE(PQ) is invalid')
          end if
          call verisize(fval, npt)
          call verisize(smat, n, npt)
          call verisize(zmat, npt, int(npt - n - 1, kind(n)))
          call verisize(hq, n, n)
      end if

! In the NEWUOA paper, Powell replaces Q with Q_alt when
! RATIO <= 0.01 and ||G_alt|| <= 0.1||GQ|| hold for 3 consecutive
! times (eq(8.4)). But Powell's code compares ABS(RATIO) instead
! of RATIO with 0.01. Here we use RATIO, which is more efficient
! as observed in in Zhang Zaikun's PhD thesis (Section 3.3.2).
!if (abs(ratio) > 1.0e-2_RP) then
      if (ratio > 1.0E-2_RP) then
          itest = 0
      else
          galt = matprod(smat, fval)
          if (inprod(gq, gq) < 1.0E2_RP * inprod(galt, galt)) then
              itest = 0
          else
              itest = int(itest + 1, kind(itest))
          end if
      end if

! Replace Q with Q_alt when ITEST >= 3.
      if (itest >= 3) then
          gq = galt
          hq = ZERO
          fz = matprod(fval, zmat)
          fz(1:idz - 1) = -fz(1:idz - 1)
          pq = matprod(zmat, fz)
          itest = 0
      end if

      end subroutine tryqalt


      end module update_mod