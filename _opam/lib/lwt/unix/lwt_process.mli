(* This file is part of Lwt, released under the MIT license. See LICENSE.md for
   details, or visit https://github.com/ocsigen/lwt/blob/master/LICENSE.md. *)



(** Process management *)

(** This module allows you to spawn processes and communicate with them. *)

type command = string * string array
    (** A command. The first field is the name of the executable and
        the second is the list of arguments. For example:

        {[
          ("ls", [|"ls"; "-l"|])
        ]}

        Notes:

        - if the name is the empty string, then the first argument
        will be used. You should specify a name only if you do not
        want the executable to be searched in the PATH. On Windows the
        only way to enable automatic search in PATH is to pass an empty
        name.

        - it is possible to ``inline'' an argument, i.e. split it into
        multiple arguments. To do that prefix it with ["\000"]. For
        example:

        {[
          ("", [|"echo"; "\000foo bar"|])
        ]}

        is the same as:

        {[
          ("", [|"echo"; "foo"; "bar"|])
        ]}
    *)

val shell : string -> command
  (** A command executed with the shell. (with ["/bin/sh -c <cmd>"] on
      Unix and ["cmd.exe /c <cmd>"] on Windows). *)

(** All the following functions take an optional argument
    [timeout], in seconds. If specified, after expiration, the process will be
    sent a {!Unix.sigkill} signal and channels will be closed. When the channels
    are closed, any pending I/O operations on them (such as
    {!Lwt_io.read_chars}) fail with exception {!Lwt_io.Channel_closed}. *)

(** {2 High-level functions} *)

(** {3 Redirections} *)

type redirection =
    [ `Keep                     (** Point to the same file as in the parent. *)
    | `Dev_null                 (** Redirect to [/dev/null] (POSIX) or [nul] (Win32). *)
    | `Close                    (** Close the file descriptor. *)
    | `FD_copy of Unix.file_descr (** Redirect to the file pointed to by [fd].
                                      [fd] remains open in the parent.  *)
    | `FD_move of Unix.file_descr (** Redirect to the file pointed to by [fd].
                                      [fd] is then closed in the parent. *)
    ]
(** File descriptor redirections. These are used with the [~stdin], [~stdout],
    and [~stderr] arguments below to specify how the standard file descriptors
    should be redirected in the child process.
    All optional redirection arguments default to [`Keep]. *)

(** {3 Executing} *)

val exec :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> Unix.process_status Lwt.t
  (** Executes the given command and returns its exit status. *)

(** {3 Receiving} *)

val pread :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stderr : redirection ->
  command -> string Lwt.t
val pread_chars :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stderr : redirection ->
  command -> char Lwt_stream.t
val pread_line :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stderr : redirection ->
  command -> string Lwt.t
val pread_lines :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stderr : redirection ->
  command -> string Lwt_stream.t

(** {3 Sending} *)

val pwrite :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> string -> unit Lwt.t
val pwrite_chars :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> char Lwt_stream.t -> unit Lwt.t
val pwrite_line :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> string -> unit Lwt.t
val pwrite_lines :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> string Lwt_stream.t -> unit Lwt.t

(** {3 Mapping} *)

val pmap :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stderr : redirection ->
  command -> string -> string Lwt.t
val pmap_chars :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stderr : redirection ->
  command -> char Lwt_stream.t -> char Lwt_stream.t
val pmap_line :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stderr : redirection ->
  command -> string -> string Lwt.t
val pmap_lines :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stderr : redirection ->
  command -> string Lwt_stream.t -> string Lwt_stream.t

(** {2 Spawning processes} *)

(** State of a sub-process *)
type state =
  | Running
      (** The process is still running *)
  | Exited of Unix.process_status
      (** The process has exited *)

class process_none :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command ->
object
  method pid : int
    (** Pid of the sub-process *)

  method state : state
    (** Return the state of the process *)

  method kill : int -> unit
    (** [kill signum] sends [signum] to the process if it is still
        running. *)

  method terminate : unit
    (** Terminates the process. It is equivalent to [kill Sys.sigkill]
        on Unix but also works on Windows
        (unlike {!Lwt_process.process_none.kill}). *)

  method status : Unix.process_status Lwt.t
    (** Threads which wait for the sub-process to exit then returns its
        exit status *)

  method rusage : Lwt_unix.resource_usage Lwt.t
    (** Threads which wait for the sub-process to exit then returns
        its resource usages *)

  method close : Unix.process_status Lwt.t
    (** Closes the process and returns its exit status. This closes all
        channels used to communicate with the process *)
end

val open_process_none :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> process_none
val with_process_none :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> (process_none -> 'a Lwt.t) -> 'a Lwt.t

class process_in :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stderr : redirection ->
  command ->
object
  inherit process_none

  method stdout : Lwt_io.input_channel
    (** The standard output of the process *)
end

val open_process_in :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stderr : redirection ->
  command -> process_in
val with_process_in :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdin : redirection ->
  ?stderr : redirection ->
  command -> (process_in -> 'a Lwt.t) -> 'a Lwt.t

class process_out :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command ->
object
  inherit process_none

  method stdin : Lwt_io.output_channel
    (** The standard input of the process *)
end

val open_process_out :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> process_out
val with_process_out :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stdout : redirection ->
  ?stderr : redirection ->
  command -> (process_out -> 'a Lwt.t) -> 'a Lwt.t

class process :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stderr : redirection ->
  command ->
object
  inherit process_none

  method stdin : Lwt_io.output_channel
  method stdout : Lwt_io.input_channel
end

val open_process :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stderr : redirection ->
  command -> process
val with_process :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  ?stderr : redirection ->
  command -> (process -> 'a Lwt.t) -> 'a Lwt.t

class process_full :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  command ->
object
  inherit process_none

  method stdin : Lwt_io.output_channel
  method stdout : Lwt_io.input_channel
  method stderr : Lwt_io.input_channel
end

val open_process_full :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  command -> process_full
val with_process_full :
  ?timeout : float ->
  ?env : string array ->
  ?cwd : string ->
  command -> (process_full -> 'a Lwt.t) -> 'a Lwt.t
