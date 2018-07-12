// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

bool FieldHasFunctionLiteralInitializer(const Field& field,
                                        TokenPosition* start,
                                        TokenPosition* end) {
  Zone* zone = Thread::Current()->zone();
  const Script& script = Script::Handle(zone, field.Script());

  TranslationHelper translation_helper(Thread::Current());
  translation_helper.InitFromScript(script);

  KernelReaderHelper kernel_reader_helper(
      zone, &translation_helper, Script::Handle(zone, field.Script()),
      ExternalTypedData::Handle(zone, field.KernelData()),
      field.KernelDataProgramOffset());
  kernel_reader_helper.SetOffset(field.kernel_offset());
  kernel::FieldHelper field_helper(&kernel_reader_helper);
  field_helper.ReadUntilExcluding(kernel::FieldHelper::kEnd, true);
  return field_helper.FieldHasFunctionLiteralInitializer(start, end);
}

KernelLineStartsReader::KernelLineStartsReader(
    const dart::TypedData& line_starts_data,
    dart::Zone* zone)
    : line_starts_data_(line_starts_data) {
  TypedDataElementType type = line_starts_data_.ElementType();
  if (type == kInt8ArrayElement) {
    helper_ = new KernelInt8LineStartsHelper();
  } else if (type == kInt16ArrayElement) {
    helper_ = new KernelInt16LineStartsHelper();
  } else if (type == kInt32ArrayElement) {
    helper_ = new KernelInt32LineStartsHelper();
  } else {
    UNREACHABLE();
  }
}

intptr_t KernelLineStartsReader::LineNumberForPosition(
    intptr_t position) const {
  intptr_t line_count = line_starts_data_.Length();
  intptr_t current_start = 0;
  for (intptr_t i = 0; i < line_count; ++i) {
    current_start += helper_->At(line_starts_data_, i);
    if (current_start > position) {
      // If current_start is greater than the desired position, it means that
      // it is for the line after |position|. However, since line numbers
      // start at 1, we just return |i|.
      return i;
    }

    if (current_start == position) {
      return i + 1;
    }
  }
  return line_count;
}

void KernelLineStartsReader::LocationForPosition(intptr_t position,
                                                 intptr_t* line,
                                                 intptr_t* col) const {
  intptr_t line_count = line_starts_data_.Length();
  intptr_t current_start = 0;
  intptr_t previous_start = 0;
  for (intptr_t i = 0; i < line_count; ++i) {
    current_start += helper_->At(line_starts_data_, i);
    if (current_start > position) {
      *line = i;
      if (col != NULL) {
        *col = position - previous_start + 1;
      }
      return;
    }
    if (current_start == position) {
      *line = i + 1;
      if (col != NULL) {
        *col = 1;
      }
      return;
    }
    previous_start = current_start;
  }

  // If the start of any of the lines did not cross |position|,
  // then it means the position falls on the last line.
  *line = line_count;
  if (col != NULL) {
    *col = position - current_start + 1;
  }
}

void KernelLineStartsReader::TokenRangeAtLine(
    intptr_t source_length,
    intptr_t line_number,
    TokenPosition* first_token_index,
    TokenPosition* last_token_index) const {
  ASSERT(line_number <= line_starts_data_.Length());
  intptr_t cumulative = 0;
  for (intptr_t i = 0; i < line_number; ++i) {
    cumulative += helper_->At(line_starts_data_, i);
  }
  *first_token_index = dart::TokenPosition(cumulative);
  if (line_number == line_starts_data_.Length()) {
    *last_token_index = dart::TokenPosition(source_length);
  } else {
    *last_token_index = dart::TokenPosition(
        cumulative + helper_->At(line_starts_data_, line_number) - 1);
  }
}

int32_t KernelLineStartsReader::KernelInt8LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt8(index);
}

int32_t KernelLineStartsReader::KernelInt16LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt16(index << 1);
}

int32_t KernelLineStartsReader::KernelInt32LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt32(index << 2);
}

}  // namespace kernel

}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)