
!****************************************************************
!
! info:
!
! iformat
!		-2  file closed (read EOF)
!		-1  no file given
!		 0  fem unformatted
!		 1  fem unformatted
!		 2  ts formatted
!
! nintp		if 0 -> constant (do not read any more file)
!
! nvar		on entry: expected
!		on return: what has been read (should be checked)
! nexp		0 < nexp <= nkn
! lexp		vertical dimension, 0 if 2D field is expected
! np		number of points in file
! lmax		number of vertical points in file (lmax > 0)
!
! how to check for things:
!
! bnofile = iformat < 0				no file open
! bfem = iformat == 0 .or. iformat == 1		fem file format
! bts = iformat == 2				ts file format
! bformat = iformat == 1			formatted fem file
! bconst = nintp == 0				constant field
! b2d = lexp == 0				2D field expected
! bonepoint					only one point stored
!
! todo:
!
! time record -> integer, real, double
! date/time
! regular fields
!
!****************************************************************

!================================================================
	module intp_fem_file
!================================================================

	implicit none

	type, private :: info
	  integer :: iunit = 0
	  integer :: iformat = 0
	  integer :: nvers = 0
	  integer :: ntype = 0
	  integer :: nvar = 0
	  integer :: nintp = 0		!if 0 -> constant
	  integer :: irec = 0
	  integer :: np = 0		!horizontal points in file
	  integer :: lmax = 0		!vertical layers in file
	  integer :: nexp = 0		!expected horizontal points
	  integer :: lexp = 0		!expected vertical points (0 for 2D)
	  integer :: ilast = 0		!last entry in time

	  character*80 :: file = ' '
	  logical :: bonepoint = .false.	!only one point stored

	  integer, allocatable :: nodes(:)
	  double precision, allocatable :: time(:)
	  real, allocatable :: data(:,:,:,:)

	  integer time_file			!maybe not needed
	  character*80, allocatable :: strings_file(:)
	  real, allocatable :: data_file(:,:,:)
	  real, allocatable :: hlv_file(:)
	  integer, allocatable :: ilhkv_file(:)
	  real, allocatable :: hd_file(:)
	end type info

	logical, parameter :: bassert = .true.

	integer, parameter :: ndim = 100
	type(info), save, dimension(ndim) :: pinfo

	integer, save :: idnext = 0

	integer, save :: nkn_fem = 0
	integer, save :: nlv_fem = 0
	integer, save, allocatable :: ilhkv_fem(:)
	real, save, allocatable :: hd_fem(:)
	real, save, allocatable :: hlv_fem(:)
	real, save, allocatable :: hl_fem(:)		!aux array
	real, save, allocatable :: hz_fem(:)		!aux array
	real, save, allocatable :: val_fem(:)		!aux array

!================================================================
	contains
!================================================================

!****************************************************************

	subroutine iff_print_info(idp)

	integer idp	!print info on this id, if 0 all info

	integer id,ids,ide

	if( idp <= 0 ) then
	  ids = 1
	  ide = idnext
	else
	  ids = idp
	  ide = idp
	end if

	write(6,1010)
	do id=ids,ide
	  write(6,1000) id,pinfo(id)%iunit,pinfo(id)%nvar
     +			,pinfo(id)%nintp,pinfo(id)%iformat
     +			,pinfo(id)%file
	end do

	return
 1010	format('   id unit nvar intp form file')
 1000	format(5i5,1x,a40)
	end subroutine iff_print_info

!****************************************************************

	subroutine iff_print_file_info(id)

	integer id

	write(6,*) 'fem file info: ',id
	write(6,*) 'other information still needed'

	end subroutine iff_print_file_info

!****************************************************************

	subroutine iff_close_file(id)

	integer id

	pinfo(id)%iformat = -2
	call iff_allocate_file_arrays(id,0,0,0)
	close(pinfo(id)%iunit)
	pinfo(id)%iunit = -2

	end subroutine iff_close_file

!****************************************************************

	subroutine iff_delete_entry(id)

	integer id

	deallocate(pinfo(id)%strings_file)

	deallocate(pinfo(id)%time)
	deallocate(pinfo(id)%data)

	deallocate(pinfo(id)%hlv_file)
	deallocate(pinfo(id)%data_file)
	deallocate(pinfo(id)%ilhkv_file)
	deallocate(pinfo(id)%hd_file)

	end subroutine iff_delete_entry

!****************************************************************

	subroutine iff_init_entry(id)

	integer id

	if( nkn_fem == 0 ) then
	  write(6,*) 'iff routines have not been initialized'
	  write(6,*) 'iff_init_global() must be called first'
	  stop 'error stop iff_init_entry: no initialization'
	end if

	pinfo(id)%iunit = 0

	end subroutine iff_init_entry

!****************************************************************
!****************************************************************
!****************************************************************

	subroutine iff_get_var_description(id,ivar,string)

	integer id
	integer ivar
	character*(*) string

	integer nvar

	nvar = pinfo(id)%nvar
	if( ivar < 1 .or. ivar > nvar ) goto 99

	string = pinfo(id)%strings_file(ivar)

	return
   99	continue
	write(6,*) 'error in parameter'
	write(6,*) 'ivar,nvar: ',ivar,nvar
	stop 'error stop iff_get_var_description'
	end subroutine iff_get_var_description

!****************************************************************

	subroutine iff_set_var_description(id,ivar,string)

	integer id
	integer ivar
	character*(*) string

	integer nvar

	nvar = pinfo(id)%nvar
	if( ivar < 1 .or. ivar > nvar ) goto 99

	pinfo(id)%strings_file(ivar) = string

	return
   99	continue
	write(6,*) 'error in parameter'
	write(6,*) 'ivar,nvar: ',ivar,nvar
	stop 'error stop iff_get_var_description'
	end subroutine iff_set_var_description

!****************************************************************

	function iff_get_nvar(id)

	integer iff_get_nvar
	integer id

	iff_get_nvar = pinfo(id)%nvar

	end function iff_get_nvar

!****************************************************************

	function iff_is_onepoint(id)

	logical iff_is_onepoint
	integer id

	iff_is_onepoint = pinfo(id)%bonepoint

	end function iff_is_onepoint

!****************************************************************

	function iff_is_constant(id)

	logical iff_is_constant
	integer id

	iff_is_constant = pinfo(id)%nintp == 0

	end function iff_is_constant

!****************************************************************

	function iff_has_file(id)

	logical iff_has_file
	integer id

	iff_has_file = pinfo(id)%iformat /= -1

	end function iff_has_file

!****************************************************************
!****************************************************************
!****************************************************************

	subroutine iff_init_global(nkn,nlv,ilhkv,hkv,hlv)

! passes params and arrays from fem needed for interpolation
!
! should be only called once at the beginning of the simulation

	integer nkn
	integer nlv
	integer ilhkv(nkn)
	real hkv(nkn)
	real hlv(nlv)

	integer i

	if( nkn_fem == 0 ) then
	  do i=1,ndim
	    pinfo(i)%iunit = 0
	  end do
	end if

	if( nkn /= nkn_fem .or. nlv /= nlv_fem ) then
	  if( nkn_fem > 0 ) then
	    deallocate(ilhkv_fem,hd_fem,hlv_fem)
	    deallocate(hl_fem,hz_fem,val_fem)
	  end if
	  allocate(ilhkv_fem(nkn),hd_fem(nkn),hlv_fem(nlv))
	  allocate(hl_fem(nlv),hz_fem(0:nlv),val_fem(nlv))
	end if

	nkn_fem = nkn
	nlv_fem = nlv
	ilhkv_fem = ilhkv
	hd_fem = hkv
	hlv_fem = hlv

	end subroutine iff_init_global

!****************************************************************

	subroutine iff_init(it,file,nvar,nexp,lexp,nintp,nodes,vconst,id)

	integer it		!initial time
	character*(*) file	!file name
	integer nvar		!expected number of variables (might change)
	integer nexp		!expected number of points
	integer lexp		!expected max vertical data (0 for 2D)
	integer nintp		!requested interpolation (2 linear, 4 cubic)
	integer nodes(nexp)	!internal nodes numbers if nexp < nkn
	real vconst(nvar)	!constant values in case no file is given
	integer id		!identification of file info (return)

	integer iformat,iunit
	integer ierr
	integer nvar_orig
	integer date,time
	logical bok,bformat
	logical bts,bfem,bnofile

	!---------------------------------------------------------
	! get new id for file
	!---------------------------------------------------------

	idnext = idnext + 1
	if( idnext > ndim ) then
	  stop 'error stop iff_init: too many files opened'
	end if
	id = idnext

	call iff_init_entry(id)

	!---------------------------------------------------------
	! check input parameters
	!---------------------------------------------------------

	if( nvar < 1 ) goto 97
	if( nexp < 1 ) goto 97
	if( nexp > nkn_fem ) goto 97
	if( lexp < 0 ) goto 97
	if( nintp < 1 ) goto 97

	!---------------------------------------------------------
	! get info on file
	!---------------------------------------------------------

	nvar_orig = nvar

	call iff_get_file_info(file,nexp,nvar,iformat)

	bts = iformat == 2
	bnofile = iformat < 0
	bfem = iformat == 0 .or. iformat == 1

	if( file /= ' ' .and. bnofile ) goto 99

	if( nvar <= 0 ) nvar = nvar_orig

	!---------------------------------------------------------
	! store information
	!---------------------------------------------------------

	pinfo(id)%iunit = -1
	pinfo(id)%nvar = nvar
	pinfo(id)%nintp = nintp
	pinfo(id)%iformat = iformat
	pinfo(id)%file = file
	pinfo(id)%nexp = nexp
	pinfo(id)%lexp = lexp

	!---------------------------------------------------------
	! get data description and allocate data structure
	!---------------------------------------------------------

	if( nexp > 0 .and. nexp /= nkn_fem ) then	!lateral BC
	  allocate(pinfo(id)%nodes(nexp))
	  pinfo(id)%nodes = nodes
	end if

	allocate(pinfo(id)%strings_file(nvar))

	if( bfem ) then
          call fem_file_get_data_description(file
     +				,pinfo(id)%strings_file,ierr)
	  if( ierr /= 0 ) goto 98
	else if( bts ) then
	  pinfo(id)%bonepoint = .true.
	  pinfo(id)%strings_file = ' '
	else if( bnofile ) then		!constant
	  pinfo(id)%nintp = 0
	  pinfo(id)%ilast = 1
	  pinfo(id)%bonepoint = .true.
	  pinfo(id)%strings_file = ' '
	  call iff_allocate_fem_data_structure(id)
	  pinfo(id)%data_file(1,1,:) = vconst
	else
	  stop 'error stop iff_init: internal error (3)'
	end if

	!---------------------------------------------------------
	! finally open files
	!---------------------------------------------------------

	if( bnofile ) then
	  return
	else if( bfem ) then
	  call fem_file_read_open(file,nexp,iunit,bformat)
	else if( bts ) then
	  call ts_open_file(file,nvar,date,time,iunit)
	  ! date not yet ready
	else
	  stop 'error stop iff_init: internal error (3)'
	end if

	if( iunit < 0 ) goto 99
	pinfo(id)%iunit = iunit

	write(6,*) 'file opened: ',id,file

	!---------------------------------------------------------
	! populate data base
	!---------------------------------------------------------

	call iff_populate_records(id,it)

	!---------------------------------------------------------
	! end of routine
	!---------------------------------------------------------

	return
   97	continue
	write(6,*) 'error in input parameters of file: ',file
	write(6,*) 'nvar: ',nvar
	write(6,*) 'nexp,lexp: ',nexp,lexp
	write(6,*) 'nintp: ',nintp
	write(6,*) 'nkn_fem: ',nkn_fem
	stop 'error stop iff_init'
   98	continue
	write(6,*) 'error reading data description of file: ',file
	stop 'error stop iff_init'
   99	continue
	write(6,*) 'error opening file: ',file
	stop 'error stop iff_init'
	end subroutine iff_init

!****************************************************************

	subroutine iff_get_file_info(file,nexp,nvar,iformat)

c coputes info on type of file
c
c	-1	no file
c	 0	unformatted
c	 1	formatted
c	 2	time series

	character*(*) file
	integer nexp
	integer nvar
	integer iformat		!info on file type (return)

	logical bformat

	iformat = -1
	if( file == ' ' ) return

	call fem_file_test_formatted(file,nexp,nvar,bformat)

	if( nvar > 0 ) then
	  iformat = 0
	  if( bformat ) iformat = 1
	else
	  call ts_get_file_info(file,nvar)
	  if( nvar > 0 ) iformat = 2
	end if

	end subroutine iff_get_file_info

!****************************************************************

	subroutine iff_populate_records(id,itinit)

	integer id
	integer itinit

	integer it,it2,idt,its,itold
	integer nintp,i
	logical bok,bts

        if( .not. iff_read_next_record(id,it) ) goto 99

        bok = iff_peek_next_record(id,it2)

	if( bok ) then				!at least two records
		nintp = pinfo(id)%nintp
		call iff_assert(nintp > 0,'nintp<=0')

                idt = it2 - it
                if( idt <= 0 ) goto 98
                its = itinit - nintp*idt	!first record needed

		itold = it
                do while( it < its )
                        bok = iff_read_next_record(id,it)
                        if( .not. bok ) goto 97
			idt = it - itold	!if time step changes
                	if( idt <= 0 ) goto 98
			its = itinit - nintp*idt
			itold = it
                end do

		call iff_allocate_fem_data_structure(id)

                call iff_space_interpolate(id,1,it)
                do i=2,nintp
                        bok = iff_read_next_record(id,it)
                        if( .not. bok ) goto 96
                        call iff_space_interpolate(id,i,it)
                end do

		pinfo(id)%ilast = nintp
	else					!constant field
		pinfo(id)%nintp = 0
		pinfo(id)%ilast = 1
		call iff_allocate_fem_data_structure(id)
                call iff_space_interpolate(id,1,it)
		call iff_close_file(id)
        end if
		
	return
   96	continue
	write(6,*) 'cannot find enough time records'
	write(6,*) 'would need at least ',nintp
	call iff_print_file_info(id)
	stop 'error stop iff_populate_records'
   97	continue
	write(6,*) 'cannot find time record'
	write(6,*) 'looking at least for it = ',its
	call iff_print_file_info(id)
	stop 'error stop iff_populate_records'
   98	continue
	write(6,*) 'time step less than 0'
	write(6,*) 'this happens at it = ',it
	call iff_print_file_info(id)
	stop 'error stop iff_populate_records'
   99	continue
	write(6,*) 'error reading first record'
	call iff_print_file_info(id)
	stop 'error stop iff_populate_records'
	end  subroutine iff_populate_records

!****************************************************************

	subroutine iff_allocate_fem_data_structure(id)

	integer id

	integer nexp,lexp,nvar,nintp
	logical bonepoint

	bonepoint = pinfo(id)%bonepoint
	nvar = pinfo(id)%nvar
	nexp = pinfo(id)%nexp
	lexp = max(1,pinfo(id)%lexp)
	nintp = max(1,pinfo(id)%nintp)

	if( bonepoint ) then	! time series or constant - store only one point
	  allocate(pinfo(id)%time(nintp))
	  allocate(pinfo(id)%data(1,1,nvar,nintp))
	else
	  allocate(pinfo(id)%time(nintp))
	  allocate(pinfo(id)%data(lexp,nexp,nvar,nintp))
	end if

	pinfo(id)%time = 0.
	pinfo(id)%data = 0.

	end subroutine iff_allocate_fem_data_structure

!****************************************************************

        function iff_read_next_record(id,it)

	logical iff_read_next_record
	integer id
	integer it

        if( iff_read_header(id,it) ) then
          call iff_read_data(id,it)
	  iff_read_next_record = .true.
	else
	  call iff_close_file(id)
	  iff_read_next_record = .false.
	end if

        end function iff_read_next_record

!****************************************************************

        function iff_peek_next_record(id,it)

! just gets new time stamp of next record

	logical iff_peek_next_record
	integer id
	integer it

	integer iunit
	integer nvers,np,lmax,nvar,ntype
	integer ierr,iformat
	real f(1)
	logical bts,bformat,bnofile

	iunit = pinfo(id)%iunit
	iformat = pinfo(id)%iformat
	bnofile = iformat < 0
	bts = iformat == 2
	bformat = iformat == 1

	iff_peek_next_record = .false.

	if( bnofile ) then
	  return
	else if( bts ) then
	  nvar = 0
	  call ts_peek_next_record(iunit,nvar,it,f,ierr)
	else
          call fem_file_peek_params(bformat,iunit,it
     +                          ,nvers,np,lmax,nvar,ntype,ierr)
	end if

	iff_peek_next_record = ( ierr == 0 )
	if( ierr .gt. 0 ) goto 99

	return
   99	continue
	write(6,*) 'read error in reading file header'
	call iff_print_file_info(id)
	stop 'error stop iff_peek_next_record'
        end function iff_peek_next_record

!****************************************************************

        function iff_read_header(id,it)

	logical iff_read_header
	integer id
	integer it

	logical bformat,bts,bnofile
	integer nvers,np,lmax,nvar,ntype
	integer iunit,ierr,iformat
	integer ivar
	real f(pinfo(id)%nvar)

	iff_read_header = .false.

	iunit = pinfo(id)%iunit
	iformat = pinfo(id)%iformat
	bformat = iformat == 1
	bts = iformat == 2
	bnofile = iformat < 0

	if( bnofile ) return		!no header to read

	pinfo(id)%irec = pinfo(id)%irec + 1

	if( bts ) then
	  nvar = pinfo(id)%nvar
	  call ts_read_next_record(iunit,nvar,it,f,ierr)
	else
          call fem_file_read_params(bformat,iunit,it
     +                          ,nvers,np,lmax,nvar,ntype,ierr)
	end if

	if( ierr < 0 ) return
	if( ierr > 0 ) goto 99
	if( nvar /= pinfo(id)%nvar ) goto 98

	pinfo(id)%time_file = it

	if( bts ) then
	  call iff_allocate_file_arrays(id,nvar,1,1)
	  pinfo(id)%data_file(1,1,:) = f	!we have already read the data
	else
	  pinfo(id)%nvers = nvers
	  pinfo(id)%ntype = ntype
	  call iff_allocate_file_arrays(id,nvar,np,lmax)
	  call fem_file_read_hlv(bformat,iunit,lmax
     +					,pinfo(id)%hlv_file,ierr)
	  if( ierr /= 0 ) goto 97
	end if

	iff_read_header = .true.

	return
   97	continue
	write(6,*) 'read error in reading hlv header'
	call iff_print_file_info(id)
	stop 'error stop iff_read_header'
   98	continue
	write(6,*) 'cannot change number of variables'
	call iff_print_file_info(id)
	write(6,*) 'nvar_old: ',pinfo(id)%nvar,' nvar_new: ',nvar
	stop 'error stop iff_read_header'
   99	continue
	write(6,*) 'read error in reading file header'
	call iff_print_file_info(id)
	stop 'error stop iff_read_header'
	end function iff_read_header

!****************************************************************

	subroutine iff_allocate_file_arrays(id,nvar,np,lmax)

! allocates fem data structure
!
! if np/lmax are different from stored ones: first deallocate, then alloacte
! if np/lmax == 0: only deallocate

	integer id
	integer nvar
	integer np
	integer lmax

	integer lm

	!---------------------------------------------------------
	! check input params
	!---------------------------------------------------------

	if( np < 0 .or. lmax < 0 ) goto 99

	!---------------------------------------------------------
	! see if everything is the same
	!---------------------------------------------------------

	if( np == pinfo(id)%np .and. lmax == pinfo(id)%lmax ) return

	!---------------------------------------------------------
	! check consistency
	!---------------------------------------------------------

	if( pinfo(id)%np > 0 .and. pinfo(id)%lmax == 0 ) goto 98
	if( pinfo(id)%np == 0 .and. pinfo(id)%lmax > 0 ) goto 98
	if( np > 0 .and. lmax == 0 ) goto 98
	if( np == 0 .and. lmax > 0 ) goto 98

	!---------------------------------------------------------
	! deallocate old arrays
	!---------------------------------------------------------

	if( pinfo(id)%np > 0 .or. pinfo(id)%lmax > 0 ) then
	  deallocate(pinfo(id)%hlv_file)
	  deallocate(pinfo(id)%data_file)
	  deallocate(pinfo(id)%ilhkv_file)
	  deallocate(pinfo(id)%hd_file)
	end if

	!---------------------------------------------------------
	! allocate new arrays
	!---------------------------------------------------------

	pinfo(id)%np = np
	pinfo(id)%lmax = lmax
	if( np > 0 .or. lmax > 0 ) then
	  allocate(pinfo(id)%hlv_file(lmax))
	  allocate(pinfo(id)%data_file(lmax,np,nvar))
	  allocate(pinfo(id)%ilhkv_file(np))
	  allocate(pinfo(id)%hd_file(np))
	end if

	pinfo(id)%hlv_file = 0.
	pinfo(id)%data_file = 0.
	pinfo(id)%ilhkv_file = 0
	pinfo(id)%hd_file = 0.

	!---------------------------------------------------------
	! end of routine
	!---------------------------------------------------------

	return
   98	continue
	write(6,*) 'error in parameters: '
	write(6,*) 'stored parameters: '
	write(6,*) 'np = ',pinfo(id)%np,' lmax = ',pinfo(id)%lmax
	write(6,*) 'requested parameters: '
	write(6,*) 'np = ',np,' lmax = ',lmax
	stop 'error stop iff_allocate_file_arrays: internal error (1)'
   99	continue
	write(6,*) 'error in parameters: '
	write(6,*) 'np = ',np,' lmax = ',lmax
	stop 'error stop iff_allocate_file_arrays'
	end subroutine iff_allocate_file_arrays

!****************************************************************

        subroutine iff_read_data(id,it)

	integer id
	integer it

	integer iunit,nvers,np,lmax
	integer nlvdim,nvar
	integer ierr,i
	logical bformat,bnofile,bts
	character*60 string

	bts = pinfo(id)%iformat == 2
	bformat = pinfo(id)%iformat == 1
	bnofile = pinfo(id)%iformat < 0

	if( bnofile ) return

	iunit = pinfo(id)%iunit
	nvers = pinfo(id)%nvers
	np = pinfo(id)%np
	lmax = pinfo(id)%lmax
	nvar = pinfo(id)%nvar

	nlvdim = lmax

	if( bts ) then
	  ! ts data has already been read
	else
	  do i=1,nvar
            call fem_file_read_data(bformat,iunit
     +                          ,nvers,np,lmax
     +                          ,pinfo(id)%ilhkv_file
     +                          ,pinfo(id)%hd_file
     +                          ,string,nlvdim
     +				,pinfo(id)%data_file
     +				,ierr)
	    if( ierr /= 0 ) goto 99
	    if( string /= pinfo(id)%strings_file(i) ) goto 98
	  end do
	end if

	return
   98	continue
	write(6,*) 'string description has changed for var ',i
	write(6,*) 'time: ',it
	write(6,*) 'old: ',pinfo(id)%strings_file(i)
	write(6,*) 'new: ',string
	call iff_print_file_info(id)
	stop 'error stop iff_read_data'
   99	continue
	write(6,*) 'error reading data: ',ierr
	write(6,*) 'time: ',it
	call iff_print_file_info(id)
	stop 'error stop iff_read_data'
	end subroutine iff_read_data

!****************************************************************
!****************************************************************
!****************************************************************

	subroutine iff_space_interpolate(id,iintp,it)

	integer id
	integer iintp
	integer it

	integer nintp,np,nexp,lmax,ip
	integer ivar,nvar,ntype
	logical bts

        pinfo(id)%time(iintp) = it

        ntype = pinfo(id)%ntype
        nintp = pinfo(id)%nintp
        np = pinfo(id)%np
        nexp = pinfo(id)%nexp
	bts = pinfo(id)%iformat == 2

	if( nintp > 0 .and. iintp > nintp ) goto 99
	if( nintp == 0 .and. iintp > 1 ) goto 99
	if( ntype > 0 ) goto 97

	if( bts ) then
          nvar = pinfo(id)%nvar
	  do ivar=1,nvar
	    pinfo(id)%data(1,1,ivar,iintp) = pinfo(id)%data_file(1,1,ivar)
	  end do
	else if( np == 1 ) then
	  do ip=1,nexp
	    call iff_handle_vertical(id,iintp,1,ip)
	  end do
	else if( np /= nexp ) then
	  goto 98
	else
	  do ip=1,np
	    call iff_handle_vertical(id,iintp,ip,ip)
	  end do
	end if

	return
   97	continue
	write(6,*) 'cannot yet handle ntype > 0'
	!call iff_print_file_info(id)
	stop 'error stop iff_space_interpolate'
   98	continue
	write(6,*) 'error in number of points: ',np,nexp
	!call iff_print_file_info(id)
	stop 'error stop iff_space_interpolate'
   99	continue
	write(6,*) 'error in parameters: ',iintp,nintp
	!call iff_print_file_info(id)
	stop 'error stop iff_space_interpolate'
	end subroutine iff_space_interpolate

!****************************************************************

	subroutine iff_handle_vertical(id,iintp,ip_from,ip_to)

	integer id
	integer iintp
	integer ip_from,ip_to

	integer lmax,lexp

        lmax = pinfo(id)%lmax
        lexp = pinfo(id)%lexp

	if( lmax == 1 ) then		!2D field given
	  call iff_distribute_vertical(id,iintp,ip_from,ip_to)
	else
	  if( lexp < 1 ) goto 99	!3D field given but 2D needed
	  if( lexp == 1 ) then
	    call iff_integrate_vertical(id,iintp,ip_from,ip_to)
	  else
	    call iff_interpolate_vertical(id,iintp,ip_from,ip_to)
	  end if
	end if

	return
   99	continue
	write(6,*) 'applying 3D data to 2D field'
	call iff_print_file_info(id)
	stop 'error stop iff_handle_vertical'
	end subroutine iff_handle_vertical

!****************************************************************

	subroutine iff_distribute_vertical(id,iintp,ip_from,ip_to)

! lmax must be 1

	integer id
	integer iintp
	integer ip_from,ip_to

	integer lfem,l,ipl,lexp
	integer ivar,nvar
	real value

        nvar = pinfo(id)%nvar
	lexp = pinfo(id)%lexp

	if( lexp <= 1 ) then		!2D
	  lfem = 1
	else				!3D
	  ipl = ip_to
	  if( pinfo(id)%nexp /= nkn_fem ) ipl = pinfo(id)%nodes(ip_to)
	  lfem = ilhkv_fem(ipl)
	end if

	do ivar=1,nvar
	  value = pinfo(id)%data_file(1,ip_from,ivar)
	  do l=1,lfem
	    pinfo(id)%data(l,ip_to,ivar,iintp) = value
	  end do
	end do

	end subroutine iff_distribute_vertical

!****************************************************************

	subroutine iff_integrate_vertical(id,iintp,ip_from,ip_to)

! lexp/lfem must be 1

	integer id
	integer iintp
	integer ip_from,ip_to

	integer lmax,l
	integer ivar,nvar
	integer nsigma
	double precision acum,htot
	real h,z
	real hsigma
	real value,hlayer
	real hl(pinfo(id)%lmax)

        nvar = pinfo(id)%nvar
	lmax = pinfo(id)%ilhkv_file(ip_from)
	h = pinfo(id)%hd_file(ip_from)
	z = 0.

	call compute_sigma_info(lmax,pinfo(id)%hlv_file,nsigma,hsigma)
	call get_layer_thickness(lmax,nsigma,hsigma,z,h
     +					,pinfo(id)%hlv_file,hl)

	do ivar=1,nvar
	  acum = 0.
	  htot = 0.
	  do l=1,lmax
	    value = pinfo(id)%data_file(l,ip_from,ivar)
	    hlayer = hl(l)
	    acum = acum + value*hlayer
	    htot = htot + hlayer
	  end do
	  pinfo(id)%data(1,ip_to,ivar,iintp) = acum / htot
	end do

	end subroutine iff_integrate_vertical

!****************************************************************

	subroutine iff_interpolate_vertical(id,iintp,ip_from,ip_to)

c global lmax and lexp are > 1

	integer id
	integer iintp
	integer ip_from,ip_to

	logical bcenter,bcons
	integer lmax,l,ipl,lfem
	integer ivar,nvar
	integer nsigma
	double precision acum,htot
	real h,z,hfem
	real hsigma
	real value,hlayer
	real hl(pinfo(id)%lmax)
	real hz_file(0:pinfo(id)%lmax+1)
	real val_file(pinfo(id)%lmax+1)

	bcenter = .false.
	bcons = .false.

        nvar = pinfo(id)%nvar
	lmax = pinfo(id)%ilhkv_file(ip_from)

	ipl = ip_to
	if( pinfo(id)%nexp /= nkn_fem ) ipl = pinfo(id)%nodes(ip_to)
	lfem = ilhkv_fem(ipl)

	if( lmax <= 1 ) then
	  call iff_distribute_vertical(id,iintp,ip_from,ip_to)
	  return
	else if( lfem <= 1 ) then
	  call iff_integrate_vertical(id,iintp,ip_from,ip_to)
	  return
	end if

	z = 0.

	h = pinfo(id)%hd_file(ip_from)
	call compute_sigma_info(lmax,pinfo(id)%hlv_file,nsigma,hsigma)
	call get_layer_thickness(lmax,nsigma,hsigma,z,h
     +					,pinfo(id)%hlv_file,hl)
	call get_bottom_of_layer(bcenter,lmax,z,hl,hz_file(1))
	hz_file(0) = z

	hfem = hd_fem(ipl)
	call compute_sigma_info(lfem,hlv_fem,nsigma,hsigma)
	call get_layer_thickness(lfem,nsigma,hsigma,z,hfem
     +					,hlv_fem,hl_fem)
	call get_bottom_of_layer(bcenter,lfem,z,hl_fem,hz_fem(1))
	hz_fem(0) = z

	do ivar=1,nvar
	  do l=1,lmax
	    val_file(l) = pinfo(id)%data_file(l,ip_from,ivar)
	  end do
	  call intp_vert(bcons,lmax,hz_file,val_file,lfem,hz_fem,val_fem)
	  do l=1,lfem
	    pinfo(id)%data(l,ip_to,ivar,iintp) = val_fem(l)
	  end do
	end do

	end subroutine iff_interpolate_vertical

!****************************************************************
!****************************************************************
!****************************************************************

	subroutine iff_time_interpolate(id,itact,ivar,ldim,ndim,value)

	integer id
	integer itact
	integer ivar
	integer ldim		!vertical dimension of value
	integer ndim		!horizontal dimension of value
	real value(ldim,ndim,*)

	integer iv,nvar
	integer nintp,lexp,nexp
	integer ilast,ifirst
	integer it,itlast,itfirst
	logical bok
	double precision t,tc

	!---------------------------------------------------------
	! set up parameters
	!---------------------------------------------------------

        nintp = pinfo(id)%nintp
        nvar = pinfo(id)%nvar
        lexp = max(1,pinfo(id)%lexp)
        nexp = pinfo(id)%nexp
        ilast = pinfo(id)%ilast
	itlast = nint(pinfo(id)%time(ilast))
	t = itact

	!---------------------------------------------------------
	! loop until time window is centered over desidered time
	!---------------------------------------------------------

	tc = tcomp(t,nintp,ilast,pinfo(id)%time)

        do while( tc < t )
          bok = iff_read_next_record(id,it)
	  if( .not. bok ) exit
	  if( it <= itlast ) goto 99
	  ilast = mod(ilast,nintp) + 1
	  call iff_space_interpolate(id,ilast,it)
	  tc = tcomp(t,nintp,ilast,pinfo(id)%time)
	  itlast = it
        end do

        pinfo(id)%ilast = ilast

	!---------------------------------------------------------
	! some sanity checks
	!---------------------------------------------------------

	itlast = nint(pinfo(id)%time(ilast))
	ifirst = mod(ilast,nintp) + 1
	itfirst = nint(pinfo(id)%time(ifirst))
        if( itlast < itact ) goto 98
        if( itfirst > itact ) goto 98
	if( lexp > ldim ) goto 97
	if( nexp > ndim ) goto 97

	!---------------------------------------------------------
	! do the interpolation
	!---------------------------------------------------------

	if( ivar .eq. 0 ) then
	  do iv=1,nvar
            call iff_interpolate(id,t,iv,ldim,ndim,value)
	  end do
	else
          call iff_interpolate(id,t,ivar,ldim,ndim,value)
	end if

	!---------------------------------------------------------
	! end of routine
	!---------------------------------------------------------

	return
   97	continue
	write(6,*) 'incompatible dimensions'
	write(6,*) 'ldim,lexp: ',ldim,lexp
	write(6,*) 'ndim,nexp: ',ndim,nexp
	call iff_print_file_info(id)
	stop 'error stop iff_time_interpolate'
   98	continue
	write(6,*) 'file does not contain needed value'
	write(6,*) 'itlast,itact: ',itlast,itact
	call iff_print_file_info(id)
	stop 'error stop iff_time_interpolate'
   99	continue
	write(6,*) 'time record not in increasing sequence'
	write(6,*) 'itfirst,it,itlast: ',itfirst,it,itlast
	call iff_print_file_info(id)
	stop 'error stop iff_time_interpolate'
	end subroutine iff_time_interpolate

!****************************************************************

        subroutine iff_interpolate(id,t,ivar,ldim,ndim,value)

	integer id
	double precision t
	integer ivar
	integer ldim		!vertical dimension of value
	integer ndim		!horizontal dimension of value
	real value(ldim,ndim,*)

	integer nintp,lexp,nexp,ilast
	logical bonepoint,bconst,bnodes,b2d,bvar
	integer ipl,lfem,i,l,ip
	real val
	real time(pinfo(id)%nintp)
	double precision rd_intp_neville

        nintp = pinfo(id)%nintp
        lexp = max(1,pinfo(id)%lexp)
        nexp = pinfo(id)%nexp
        ilast = pinfo(id)%ilast
        bonepoint = pinfo(id)%bonepoint
	bconst = nintp == 0
	bvar = .not. bconst
	b2d = lexp <= 1
	bnodes = pinfo(id)%nexp /= nkn_fem	!use node pointer

	if( bconst .or. bonepoint ) then
	  if( bconst ) then
	    val = pinfo(id)%data(1,1,ivar,1)
	  else
	    val = rd_intp_neville(nintp,pinfo(id)%time
     +				,pinfo(id)%data(1,1,ivar,1),t)
	  end if
	  do i=1,nexp
	    do l=1,lexp
	      if( bvar ) val = pinfo(id)%data(l,i,ivar,1)
	      value(l,i,ivar) = val
	    end do
	  end do
	else
	  do i=1,nexp
	    if( b2d ) then
	      lfem = 1
	    else
	      ipl = i
	      if( nexp /= nkn_fem ) ipl = pinfo(id)%nodes(i)
	      lfem = ilhkv_fem(ipl)
	    end if
	    do l=1,lfem
	      val = rd_intp_neville(nintp,pinfo(id)%time
     +				,pinfo(id)%data(l,i,ivar,1),t)
	      value(l,i,ivar) = val
	    end do
	  end do
	end if

	end subroutine iff_interpolate

!****************************************************************

	function tcomp(t,nintp,ilast,time)

	double precision tcomp
	double precision t
	integer nintp
	integer ilast
	double precision time(:)

	integer n1,n2

	!n1=1+nintp/2
	!n2 = n1
	!if( mod(nintp,2) /= 0 .and. nintp > 1 ) n2=n2+1		!odd

	n1=1+mod(ilast+nintp/2,nintp)
	n2 = n1
	if( mod(nintp,2) /= 0 .and. nintp > 1 ) n2=mod(n2,nintp)+1	!odd

	tcomp = 0.5 * (time(n1)+time(n2))

	end function tcomp

!****************************************************************
!****************************************************************
!****************************************************************

	subroutine iff_assert(bval,text)

	logical bval
	character*(*) text

	if( bassert ) then
	  if( .not. bval ) then
	    write(6,*) 'assertion violated'
	    write(6,*) text
	    stop 'error stop iff_assert: assertion violated'
	  end if
	end if

	end subroutine iff_assert

!================================================================
	end module intp_fem_file
!================================================================
