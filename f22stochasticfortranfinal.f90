!!Stochastic version of code by Philip Coyle 


implicit none

! -----------------------------------------------------------------------
! *******************DECLARATION OF PARAMETERS AND VARIABLES*************
! -----------------------------------------------------------------------
! Model Parameters
double precision, parameter :: 				cBET 				= 0.99d0 	! Discount Factor
double precision, parameter :: 				cTHETA 			= 0.36d0	! Capital Share
double precision, parameter :: 				cDEL 				= 0.025d0	! Depreciation Rate


! Tolerance level for convergence and max itations
double precision, parameter :: 				tol			 		= 1d-3	! Convergence Tolerance
integer, parameter 					:: 				max_it 			= 10000 ! Maximum Number of Iterations
integer 										::				it		 			= 1 		! Itation Counter
integer 										:: 				converged		= 0			! Dummy for VFI Convergence


! -----------------------------------------------------------------------
! ****************************GRID SET**********************************
! -----------------------------------------------------------------------
! Set up for discritizing the state space (Capital Grid)
integer						 				  :: 				i_k, i_kpr,i_z																				! Ieration Counters for k_today and k_tomorrow grid
integer, parameter 				  :: 				n_k 				= 1000																! Size of k grid
double precision 						:: 				grid_k(n_k)																				! Allocate Space for k grid
double precision, parameter :: 				min_k 			= 0.01d0															! Minimum of k grid
double precision, parameter :: 				max_k 			= 60d0																! Maximum of k grid
double precision, parameter :: 				step_k 			= (max_k - min_k)/(dble(n_k) - 1d0) 	! Step of k grid
double precision					  :: 				k_today
double precision					  :: 				k_tomorrow
integer, parameter::	 n_z = 2
double precision:: grid_z(2) = [1.25,.20]
double precision, dimension(3,3) :: p_matrix 


! Global variables for Dynamic Progamming
double precision 						:: 				c_today
double precision 						:: 				c_today_temp

double precision 						:: 				y_today
double precision 						:: 				k_tomorrow_max
double precision 						:: 				v_today
double precision 						:: 				v_today_temp
double precision 						:: 				v_tomorrow
double precision                        ::              z_today


! Allocating space for Policy Functions
double precision 						:: 				pf_c(n_k,n_z) ! Allocate Space for Conumption Policy Function
double precision 						:: 				pf_k(n_k,n_z) ! Allocate Space for Capital Policy Function
double precision 						:: 				pf_v(n_k,n_z) ! Allocate Space for Value Function
integer 								::			    i_stat   ! Used for writing data after program has run.

end module params_grid
!p_matrix(1) = 0.977
!p_matrix(2) = 0.023
!p_matrix(3) = 0.074
!p_matrrix(4) = 0.926


! ************************************************************************
! ------------------------------------------------------------------------
! ------------------------------------------------------------------------
! program : neogrowth
!
! Description : This program will use dynamic programming techniques to solve
! a simple deterministic neoclassical growth model.
! ------------------------------------------------------------------------
! ------------------------------------------------------------------------

program neogrowth

use params_grid


implicit none

! Begin Computational Timer
integer 										::				beginning, end, rate

call system_clock(beginning, rate)

! Initialize Grids and Policy Functions
call housekeeping()

! Do Value Function Iteration
call bellman()

call system_clock(end)
write(*,*) ""
write(*,*) "******************************************************"
write(*,*) "Total elapsed time = ", real(end - beginning) / real(rate)," seconds"
write(*,*) "******************************************************"

! Write results
! call coda()

write(*,*) ""
write(*,*) "**************************************"
write(*,*) "************END OF PROGRAM************"
write(*,*) "**************************************"
write(*,*) ""

end program neogrowth

! ************************************************************************
! ************************************************************************
! ************************************************************************
! **************************** SUBROUTINES *******************************
! ************************************************************************
! ************************************************************************
! ************************************************************************


! ************************************************************************


! ------------------------------------------------------------------------
! ------------------------------------------------------------------------
! subroutine : housekeeping
!
! description : Initializes Grids and Policy Functions
! ------------------------------------------------------------------------
! ------------------------------------------------------------------------

subroutine housekeeping()

use params_grid


implicit none

! Discretizing the state space (capital)
do i_k = 1,n_k
	grid_k(i_k) = min_k + (dble(i_k) - 1d0)*step_k
	
end do

! Setting up Policy Function guesses
do i_k = 1,n_k
	do i_z = 1,n_z

		pf_c(i_k,i_z) 			    = 0d0
		pf_k(i_k,i_z) 		    	= 0d0
		pf_v(i_k,i_z)    	        = 0d0
	end do
end do



return

end subroutine housekeeping



subroutine hello()
    implicit none
    real :: markov_array(2,2)
    markov_array = reshape([0.997,0.024,0.023,0.926], [2,2])
    print *, markov_array(1,:)
    print *, markov_array(2,:)
	return 
end subroutine hello



! ************************************************************************


! ------------------------------------------------------------------------
! ------------------------------------------------------------------------
! subroutine : bellman
!
! description : Solves the dynamic programming problem for policy and value
! functions.
! ------------------------------------------------------------------------
! ------------------------------------------------------------------------

subroutine bellman()

use params_grid


implicit none
! allocating space for policy function updates
double precision 						:: 				pf_c_up(n_k,n_z)
double precision 						:: 				pf_k_up(n_k,n_z)
double precision 						:: 				pf_v_up(n_k,n_z)

double precision 						:: 				diff_c
double precision 						:: 				diff_k
double precision 						:: 				diff_v
double precision 						:: 				max_diff

real :: markov_array(2,2) = reshape([0.997,0.024,0.023,0.926], [2,2])
converged = 0
it = 1

! Begin Dynamic Programming Algo.
! Continue to iterate while VFI has not converged (converged == 0) and iteration counter is less than maximium numnber of iterations (it < max_it)
do while (converged == 0 .and. it < max_it)

	do i_k = 1,n_k ! Loop over all possible capital states
		do i_z = 1,n_z


		! ***********************************
		! Define the today's state variables
		! ***********************************
			k_today = grid_k(i_k)
			z_today = grid_z(i_z)

			! ******************************************************
			! Solve for the optimal consumption / capital investment
			! ******************************************************
			v_today = -1d10 ! Set a very low bound for value
			y_today = z_today*k_today**(cTHETA) ! income today
			do i_kpr = 1,n_k ! Loop over all possible capital chocies
				k_tomorrow = grid_k(i_kpr)

				! some values are "temp" values because we are searching exaustively for the capital/consumption choice that maximizes value
				c_today_temp = y_today + (1-cDEL)*k_today - k_tomorrow
				v_tomorrow = dot_product(pf_v(i_kpr,:),markov_array(i_z,1:2))


				c_today_temp = max(0d0,c_today_temp)
				v_today_temp = log(c_today_temp) + cBET*v_tomorrow

				if (v_today_temp > v_today) then ! if "temp" value is best so far, record value and capital choice
					v_today = v_today_temp
					k_tomorrow_max = k_tomorrow
				end if
			end do

		pf_c_up(i_k,i_z) = c_today
		pf_k_up(i_k,i_z) = k_tomorrow
		pf_v_up(i_k,i_z) = v_today
		end do
		k_tomorrow = k_tomorrow_max
		c_today = y_today + (1-cDEL)*k_today - k_tomorrow

   	  ! *******************************
	  ! ****Update Policy Functions****
	  ! *******************************
	  
	end do

	! Find the difference between the policy functions and updates
	diff_c  = maxval(abs(pf_c - pf_c_up))
	diff_k  = maxval(abs(pf_k - pf_k_up))
	diff_v  = maxval(abs(pf_v - pf_v_up))

	max_diff = diff_c + diff_k + diff_v

	if (mod(it,50) == 0) then
		write(*,*) ""
		write(*,*) "********************************************"
		write(*,*) "At itation = ", it
		write(*,*) "Max Difference = ", max_diff
		write(*,*) "********************************************"
	 end if

	if (max_diff < tol) then
		converged = 1
		write(*,*) ""
		write(*,*) "********************************************"
		write(*,*) "At itation = ", it
		write(*,*) "Max Difference = ", max_diff
		write(*,*) "********************************************"
	end if

	it = it+1

	pf_c 		= pf_c_up
	pf_k 		= pf_k_up
	pf_v		= pf_v_up
end do

return

end subroutine bellman

! ************************************************************************


! ------------------------------------------------------------------------
! ------------------------------------------------------------------------
! subroutine : coda
!
! description : Writes results to .dat file
! ------------------------------------------------------------------------
! ------------------------------------------------------------------------

subroutine coda()

use params_grid


implicit none

write(*,*) ""
write (*,*) "Writing PFs to DAT file"
open(unit = 2, file = 'pfs_neogrowth.dat', status = 'replace', action = 'write', iostat = i_stat)
200 format(f25.15,2x,f25.15,2x,f25.15,2x,f25.15,2x,f25.15,2x,f25.15,2x,f25.15,2x,f25.15,2x)

do i_k = 1,n_k
     write(2,200) grid_k(i_k), pf_c(i_k,i_z), pf_k(i_k,i_z), pf_v(i_k,i_z)
end do

return

end subroutine coda
