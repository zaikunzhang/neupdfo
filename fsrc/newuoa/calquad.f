      !subroutine calquad(vquad, d, x, xpt, gq, hq, pq, n, npt)
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      ! CALQUAD can be implemented without WCHECK. For the moment, to 
      ! produce exactly the same result as Powell's code, we use WCHECK.
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      subroutine calquad(vquad, d, x, xpt, gq, hq, pq, n, npt, wcheck)
      ! CALQUAD calculates VQUAD = Q(X + D) - Q(X), where Q is the
      ! quadratic function defined by (GQ, HQ, PQ).

      use consts, only : RP, IK, HALF, ZERO
      use lina
      implicit none

      integer(IK), intent(in) :: n, npt

      real(RP), intent(in) :: d(n), x(n), xpt(n, npt), gq(n), hq(n, n), &
     & pq(npt)
      real(RP), intent(out) :: vquad 

      integer(IK) :: i, ih, j, k 
      real(RP) :: s(n), temp!,sd
      real(RP) :: wcheck(npt)


      s = x + d  ! It is NOT applicable to the version below.

      vquad = ZERO

      ih = 0
      do j = 1, n
          vquad = vquad + d(j)*gq(j)
          do i = 1, j
              ih = ih + 1
              temp = d(i)*s(j) + d(j)*x(i)
              if (i == j) then 
                  temp = HALF*temp
              end if
              vquad = vquad + temp*hq(i, j)
          end do
      end do

!----------------------------------------------------------------------!
      ! WCHECK is the following vector in theory. We really do not need
      ! to pass it as an input. The only place that can make WCHECK
      ! different from this value is in BIGDEN, where WCHECK is
      ! calculated in another way (that is mathematically equivalent). 
!-----!wcheck = matmul(d, xpt) !---------------------------------------!
!-----!wcheck = wcheck*(half*wcheck + matmul(x, xpt)) !----------------!
!----------------------------------------------------------------------!

      do k = 1, npt
          vquad = vquad + pq(k)*wcheck(k)
      end do

      !!!!!!!!!!!!!!!!!!IMPLEMENTATON WITHOUT WCHECK!!!!!!!!!!!!!!!!!!!!
!      s = d + x + x  ! Different from the above version.
!
!      ! 1st order term plus implicit 2nd-order term
!      vquad = dot_product(d,gq)+half*sum(pq*matmul(s,xpt)*matmul(d,xpt)) 
!
!      ! explicit 2nd-order term
!      ih = 0 
!      do i = 1, n
!          do j = 1, i 
!              if (i == j) then
!                  sd = s(i)*d(i)
!              else
!                  sd = s(i)*d(j) + s(j)*d(i)
!              end if
!              ih = ih + 1
!              vquad = vquad + half * hq(j, i) * sd 
!          end do
!      end do
      !!!!!!!!!!!!!!IMPLEMENTATON WITHOUT WCHECK ENDS!!!!!!!!!!!!!!!!!!!
      return

      end subroutine calquad
