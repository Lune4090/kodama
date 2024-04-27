# Copyright (c) 2018 Numforge SARL
# Distributed under the Apache v2 License (license terms are at https://www.apache.org/licenses/LICENSE-2.0).

import ./generated/clblast_c #, clblast_netlib_c]
# Note half conversion table cannot be autogenerated
# So we do not expose the half precision (even though we expose procs that can use it there is no easy way to remove themat generation)

export clblast_c #, clblast_netlib_c

type CLBlastError* = object of IOError

template check*(status: CLBlastStatusCode) =
  let code = status # Ensure that the expression is only evaluated once, especially if there are side-effects
  if unlikely(code != CLBlastSuccess):
    raise newException(CLBlastError,
      "CLBlast encoutered an error: [Code " & $int(code) & "]: " & $code)