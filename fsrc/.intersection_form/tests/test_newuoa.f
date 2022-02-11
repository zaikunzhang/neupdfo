!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! This is the intersection-form version of test_newuoa.f90.
! The file is generated automatically and is NOT intended to be readable.
!
! In the intersection form, each continued line has an ampersand at column
! 73, and each continuation line has an ampersand at column 6. A Fortran
! file in such a form can be compiled both as fixed form and as free form.
!
! See http://fortranwiki.org/fortran/show/Continuation+lines for details.
!
! Generated using the interform.m script by Zaikun ZHANG (www.zhangzk.net)
! on 11-Feb-2022.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


      module test_solver_mod
!--------------------------------------------------------------------------------------------------!
! This module tests NEWUOA on a few simple problems.
!
! Coded by Zaikun ZHANG (www.zhangzk.net).
!
! Started: September 2021
!
! Last Modified: Thursday, February 10, 2022 PM02:22:14
!--------------------------------------------------------------------------------------------------!

      implicit none
      private
      public :: test_solver


      contains


      subroutine test_solver(probs, mindim, maxdim, dimstride, nrand)

      use, non_intrinsic :: consts_mod, only : RP, IK, TWO, TEN, ZERO, H&
     &UGENUM
      use, non_intrinsic :: datetime_mod, only : year, week
      use, non_intrinsic :: memory_mod, only : safealloc
      use, non_intrinsic :: newuoa_mod, only : newuoa
      use, non_intrinsic :: noise_mod, only : noisy, noisy_calfun, orig_&
     &calfun
      use, non_intrinsic :: param_mod, only : MINDIM_DFT, MAXDIM_DFT, DI&
     &MSTRIDE_DFT, NRAND_DFT
      use, non_intrinsic :: prob_mod, only : PNLEN, PROB_T, construct, d&
     &estruct
      use, non_intrinsic :: rand_mod, only : setseed, rand, randn
      use, non_intrinsic :: string_mod, only : trimstr, istr

      implicit none

      character(len=PNLEN), intent(in), optional :: probs(:)
      integer(IK), intent(in), optional :: mindim
      integer(IK), intent(in), optional :: maxdim
      integer(IK), intent(in), optional :: dimstride
      integer(IK), intent(in), optional :: nrand

      character(len=PNLEN) :: probname
      character(len=PNLEN) :: probs_loc(100)
      integer :: rseed
      integer :: yw
      integer(IK) :: dimstride_loc
      integer(IK) :: iprint
      integer(IK) :: iprob
      integer(IK) :: irand
      integer(IK) :: maxdim_loc
      integer(IK) :: maxfun
      integer(IK) :: maxhist
      integer(IK) :: mindim_loc
      integer(IK) :: n
      integer(IK) :: nprobs
      integer(IK) :: npt
      integer(IK) :: npt_list(10)
      integer(IK) :: nrand_loc
      real(RP) :: f
      real(RP) :: ftarget
      real(RP) :: rhobeg
      real(RP) :: rhoend
      real(RP), allocatable :: fhist(:)
      real(RP), allocatable :: x(:)
      real(RP), allocatable :: xhist(:, :)
      type(PROB_T) :: prob

      if (present(probs)) then
          nprobs = int(size(probs), kind(nprobs))
          probs_loc(1:nprobs) = probs
      else
          nprobs = 5_IK
          probs_loc(1:nprobs) = ['chebyquad', 'chrosen ', 'trigsabs ', '&
     &trigssqs ', 'vardim ']
      end if

      if (present(mindim)) then
          mindim_loc = mindim
      else
          mindim_loc = MINDIM_DFT
      end if

      if (present(maxdim)) then
          maxdim_loc = maxdim
      else
          maxdim_loc = MAXDIM_DFT
      end if

      if (present(dimstride)) then
          dimstride_loc = dimstride
      else
          dimstride_loc = DIMSTRIDE_DFT
      end if

      if (present(nrand)) then
          nrand_loc = nrand
      else
          nrand_loc = NRAND_DFT
      end if

      do iprob = 1, nprobs
          probname = probs_loc(iprob)
          do n = mindim_loc, maxdim_loc, dimstride_loc
! NPT_LIST defines some extreme values of NPT.
              npt_list = [1_IK, n + 1_IK, n + 2_IK, n + 3_IK, 2_IK * n, &
     &2_IK * n + 1_IK, 2_IK * n + 2_IK, (n + 1_IK) * (n + 2_IK) / 2_IK -&
     & 1_IK, (n + 1_IK) * (n + 2_IK) / 2_IK, (n + 1_IK) * (n + 2_IK) / 2&
     &_IK + 1_IK]
              do irand = 1, int(size(npt_list) + max(0_IK, nrand_loc), k&
     &ind(irand))
! Initialize the random seed using N, IRAND, IK, and RP.
! We ALTER THE SEED weekly to test the solvers as much as possible.
                  yw = 100 * modulo(year(), 100) + week()
                  rseed = int(sum(istr(probname)) + n + irand + IK + RP &
     &+ yw)
                  call setseed(rseed)
                  if (irand <= size(npt_list)) then
                      npt = npt_list(irand)
                  else
                      npt = int(TEN * rand() * real(n, RP), kind(npt))
                  end if
                  if (rand() <= 0.2_RP) then
                      npt = 0
                  end if
                  iprint = int(sign(min(3.0_RP, 1.5_RP * abs(randn())), &
     &randn()), kind(iprint))
                  maxfun = int(2.0E2_RP * rand() * real(n, RP), kind(max&
     &fun))
                  if (rand() <= 0.2_RP) then
                      maxfun = 0
                  end if
                  maxhist = int(TWO * rand() * real(max(10_IK * n, maxfu&
     &n), RP), kind(maxhist))
                  if (rand() <= 0.2_RP) then
                      maxhist = 0
                  end if
                  if (rand() <= 0.2_RP) then
                      ftarget = -TEN**abs(TWO * randn())
                  elseif (rand() <= 0.2_RP) then
                  ! Note that the value of rand() changes.
                      ftarget = HUGENUM
                  else
                      ftarget = -HUGENUM
                  end if

                  call construct(prob, probname, n)
                  ! Construct the testing problem.

                  rhobeg = noisy(prob 
                  rhoend = max(1.0E-6_RP, rhobeg * 1.0E1_RP**(6.0_RP * r&
     &and() - 5.0_RP))
                  if (rand() <= 0.2_RP) then
                      rhoend = rhobeg
                  elseif (rand() <= 0.2_RP) then
                  ! Note that the value of rand() changes.
                      rhobeg = ZERO
                  end if
                  call safealloc(x, n)
                  ! Not all compilers support automatic allocation yet, e.g., Absoft.
                  x = noisy(prob 
                  orig_calfun => prob 

                  print '(/1A, I3, 1A, I3)', trimstr(probname)//': N = '&
     &, n, ', Random test ', irand
                  call newuoa(noisy_calfun, x, f, rhobeg=rhobeg, rhoend=&
     &rhoend, npt=npt, maxfun=maxfun, maxhist=maxhist, fhist=fhist, xhis&
     &t=xhist, ftarget=ftarget, iprint=iprint)

                  call destruct(prob)
                  ! Destruct the testing problem.
! DESTRUCT deallocates allocated arrays/pointers and nullify the pointers. Must be called.
                  deallocate (x)
                  nullify (orig_calfun)
              end do
          end do
      end do

      end subroutine test_solver


      end module test_solver_mod