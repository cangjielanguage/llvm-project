; RUN: opt -passes=cj-ir-verifier -disable-output < %s

declare i32 @personality(...)
declare i8 addrspace(1)* @llvm.cj.malloc.local.array(i8*, i64, i64)
declare i8 addrspace(1)* @llvm.cj.malloc.local.array.generic(i8*, i64)

define i8 addrspace(1)* @local_array(i8* %ti, i64 %length, i64 %size)
    gc "cangjie" personality i32 (...)* @personality {
entry:
  %array = invoke i8 addrspace(1)* @llvm.cj.malloc.local.array(
      i8* %ti, i64 %length, i64 %size)
      to label %normal unwind label %unwind

normal:
  ret i8 addrspace(1)* %array

unwind:
  %exception = landingpad { i8*, i32 } cleanup
  resume { i8*, i32 } %exception
}

define i8 addrspace(1)* @local_generic_array(i8* %ti, i64 %length)
    gc "cangjie" personality i32 (...)* @personality {
entry:
  %array = invoke i8 addrspace(1)* @llvm.cj.malloc.local.array.generic(
      i8* %ti, i64 %length)
      to label %normal unwind label %unwind

normal:
  ret i8 addrspace(1)* %array

unwind:
  %exception = landingpad { i8*, i32 } cleanup
  resume { i8*, i32 } %exception
}
