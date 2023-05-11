#ifndef _FOO_H
#define _FOO_H

#include <cassert>

namespace {
enum class SBNilType { SBNil };
const SBNilType SBNil = SBNilType::SBNil;

template <typename T> class OptionalStorage {
  union {
    char empty;
    T val;
  };
  bool hasVal;

public:
  OptionalStorage() : empty(), hasVal(false) {}
  OptionalStorage(const T &t) : val(t), hasVal(true) {}

  operator bool() const { return hasVal; }

  bool hasValue() const { return hasVal; }

  const T &value() const {
    assert(hasVal);
    return val;
  }
};
} // namespace

namespace lldb {
template <typename T> class SBOptional {
private:
  OptionalStorage<T> m_storage;
  mutable bool checked = false;

public:
  using value_type = T;

  SBOptional() = default;
  SBOptional(const T &t) : m_storage(t) {}
  SBOptional(SBNilType) : m_storage() {}

  operator bool() const & {
    checked = true;
    return m_storage.hasValue();
  }
  bool hasValue() const & {
    checked = true;
    return m_storage.hasValue();
  }

  const T &get() const & {
    assert(checked);
    return m_storage.value();
  }
};
#ifdef SWIG
%template(SBOptional_uint64_t) SBOptional<uint64_t>;
#endif
} // namespace lldb

#endif
