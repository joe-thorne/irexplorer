; ModuleID = '/workspace/out/word_frequency_05_cleanup.ll'
source_filename = "/workspace/user-programs/word_frequency.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.table = type { [256 x %struct.entry], i32 }
%struct.entry = type { [24 x i8], i32, i32 }

@main.table = internal global %struct.table zeroinitializer, align 4, !dbg !0
@main.entries = internal global [256 x %struct.entry] zeroinitializer, align 16, !dbg !37
@passage = internal global ptr @.str.4, align 8, !dbg !72
@.str = private unnamed_addr constant [4 x i8] c"fox\00", align 1, !dbg !50
@.str.1 = private unnamed_addr constant [4 x i8] c"cat\00", align 1, !dbg !55
@.str.2 = private unnamed_addr constant [18 x i8] c"fox: %d, cat: %d\0A\00", align 1, !dbg !57
@stderr = external global ptr, align 8
@.str.3 = private unnamed_addr constant [23 x i8] c"table full at word %d\0A\00", align 1, !dbg !62
@.str.4 = private unnamed_addr constant [285 x i8] c"The quick brown fox jumps over the lazy dog. The dog sleeps, and the fox runs into the forest. In the forest the fox finds a river; the river is cold and the fox is quick. A lazy dog never finds the river, but the quick fox always does. Over the hills and over the river the fox runs.\00", align 1, !dbg !67
@.str.5 = private unnamed_addr constant [23 x i8] c"%d words, %d distinct\0A\00", align 1, !dbg !76
@.str.6 = private unnamed_addr constant [11 x i8] c"%-10s %3d \00", align 1, !dbg !78
@.str.7 = private unnamed_addr constant [18 x i8] c"longest word: %s\0A\00", align 1, !dbg !83
@.str.8 = private unnamed_addr constant [27 x i8] c"mean length: %.2f letters\0A\00", align 1, !dbg !85
@.str.9 = private unnamed_addr constant [21 x i8] c"words seen once: %d\0A\00", align 1, !dbg !90

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !2 {
entry:
  call void @table_init(ptr noundef nonnull @main.table), !dbg !108
  %0 = load ptr, ptr @passage, align 8, !dbg !109
  %call = call i32 @count_words(ptr noundef nonnull @main.table, ptr noundef %0), !dbg !110
    #dbg_value(i32 %call, !111, !DIExpression(), !112)
  %call1 = call i32 @collect(ptr noundef nonnull @main.table, ptr noundef nonnull @main.entries), !dbg !113
    #dbg_value(i32 %call1, !114, !DIExpression(), !112)
  call void @report(ptr noundef nonnull @main.entries, i32 noundef %call1, i32 noundef %call), !dbg !115
  %call2 = call i32 @table_lookup(ptr noundef nonnull @main.table, ptr noundef nonnull @.str), !dbg !116
    #dbg_value(i32 %call2, !117, !DIExpression(), !112)
  %call3 = call i32 @table_lookup(ptr noundef nonnull @main.table, ptr noundef nonnull @.str.1), !dbg !118
    #dbg_value(i32 %call3, !119, !DIExpression(), !112)
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %call2, i32 noundef %call3) #8, !dbg !120
  %cmp5 = icmp ne i32 %call3, 0, !dbg !121
  %cmp.inv = icmp slt i32 %call2, 1, !dbg !121
  %narrow = or i1 %cmp.inv, %cmp5, !dbg !121
  %not. = zext i1 %narrow to i32, !dbg !121
  ret i32 %not., !dbg !122
}

; Function Attrs: noinline nounwind uwtable
define internal void @table_init(ptr noundef %table) #0 !dbg !123 {
entry:
    #dbg_value(ptr %table, !127, !DIExpression(), !128)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(8196) %table, i8 0, i64 8196, i1 false), !dbg !129
  ret void, !dbg !130
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @count_words(ptr noundef %table, ptr noundef %text) #0 !dbg !131 {
entry:
  %text.addr = alloca ptr, align 8
  %word = alloca [24 x i8], align 16
    #dbg_value(ptr %table, !134, !DIExpression(), !135)
    #dbg_value(ptr %text, !136, !DIExpression(), !135)
  store ptr %text, ptr %text.addr, align 8
    #dbg_declare(ptr %word, !137, !DIExpression(), !138)
    #dbg_value(i32 0, !139, !DIExpression(), !135)
  br label %while.cond, !dbg !140

while.cond:                                       ; preds = %if.end, %entry
  %position.0 = phi i32 [ 0, %entry ], [ %inc, %if.end ], !dbg !135
    #dbg_value(i32 %position.0, !139, !DIExpression(), !135)
    #dbg_value(ptr %text.addr, !136, !DIExpression(DW_OP_deref), !135)
  %call = call i32 @next_word(ptr noundef nonnull %text.addr, ptr noundef nonnull %word), !dbg !141
  %cmp = icmp sgt i32 %call, 0, !dbg !142
  br i1 %cmp, label %while.body, label %while.end.loopexit, !dbg !140

while.body:                                       ; preds = %while.cond
  %call2 = call i32 @table_add(ptr noundef %table, ptr noundef nonnull %word, i32 noundef %position.0), !dbg !143
  %cmp3 = icmp slt i32 %call2, 0, !dbg !146
  br i1 %cmp3, label %if.then, label %if.end, !dbg !146

if.then:                                          ; preds = %while.body
  %position.0.lcssa1 = phi i32 [ %position.0, %while.body ], !dbg !135
  %0 = load ptr, ptr @stderr, align 8, !dbg !147
  %call4 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.3, i32 noundef %position.0.lcssa1) #9, !dbg !149
  br label %while.end, !dbg !150

if.end:                                           ; preds = %while.body
  %inc = add nuw nsw i32 %position.0, 1, !dbg !151
    #dbg_value(i32 %inc, !139, !DIExpression(), !135)
  br label %while.cond, !dbg !140, !llvm.loop !152

while.end.loopexit:                               ; preds = %while.cond
  %position.0.lcssa = phi i32 [ %position.0, %while.cond ], !dbg !135
  br label %while.end, !dbg !155

while.end:                                        ; preds = %while.end.loopexit, %if.then
  %position.02 = phi i32 [ %position.0.lcssa, %while.end.loopexit ], [ %position.0.lcssa1, %if.then ]
  ret i32 %position.02, !dbg !155
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @collect(ptr noundef %table, ptr noundef %out) #0 !dbg !156 {
entry:
    #dbg_value(ptr %table, !162, !DIExpression(), !163)
    #dbg_value(ptr %out, !164, !DIExpression(), !163)
    #dbg_value(i32 0, !165, !DIExpression(), !163)
    #dbg_value(i32 0, !166, !DIExpression(), !168)
  br label %for.cond, !dbg !169

for.cond:                                         ; preds = %for.inc, %entry
  %n.0 = phi i32 [ 0, %entry ], [ %n.1, %for.inc ], !dbg !163
  %i.0 = phi i32 [ 0, %entry ], [ %inc7, %for.inc ], !dbg !170
    #dbg_value(i32 %i.0, !166, !DIExpression(), !168)
    #dbg_value(i32 %n.0, !165, !DIExpression(), !163)
  %cmp = icmp samesign ult i32 %i.0, 256, !dbg !171
  br i1 %cmp, label %for.body, label %for.end, !dbg !173

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !174
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !174
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !177
  %0 = load i32, ptr %count, align 4, !dbg !177
  %cmp1 = icmp sgt i32 %0, 0, !dbg !178
  br i1 %cmp1, label %if.then, label %for.inc, !dbg !178

if.then:                                          ; preds = %for.body
  %inc = add nsw i32 %n.0, 1, !dbg !179
    #dbg_value(i32 %inc, !165, !DIExpression(), !163)
  %idxprom2 = sext i32 %n.0 to i64, !dbg !181
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %out, i64 %idxprom2, !dbg !181
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(32) %arrayidx3, ptr noundef nonnull align 4 dereferenceable(32) %arrayidx, i64 32, i1 false), !dbg !182
  br label %for.inc, !dbg !183

for.inc:                                          ; preds = %if.then, %for.body
  %n.1 = phi i32 [ %inc, %if.then ], [ %n.0, %for.body ], !dbg !163
    #dbg_value(i32 %n.1, !165, !DIExpression(), !163)
  %inc7 = add nuw nsw i32 %i.0, 1, !dbg !184
    #dbg_value(i32 %inc7, !166, !DIExpression(), !168)
  br label %for.cond, !dbg !185, !llvm.loop !186

for.end:                                          ; preds = %for.cond
  %n.0.lcssa = phi i32 [ %n.0, %for.cond ], !dbg !163
  %conv = sext i32 %n.0.lcssa to i64, !dbg !188
  call void @qsort(ptr noundef %out, i64 noundef %conv, i64 noundef 32, ptr noundef nonnull @by_count) #8, !dbg !189
  ret i32 %n.0.lcssa, !dbg !190
}

; Function Attrs: noinline nounwind uwtable
define internal void @report(ptr noundef %entries, i32 noundef %n, i32 noundef %total) #0 !dbg !191 {
entry:
    #dbg_value(ptr %entries, !196, !DIExpression(), !197)
    #dbg_value(i32 %n, !198, !DIExpression(), !197)
    #dbg_value(i32 %total, !199, !DIExpression(), !197)
  %n. = call i32 @llvm.smin.i32(i32 %n, i32 8), !dbg !200
    #dbg_value(i32 %n., !201, !DIExpression(), !197)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.5, i32 noundef %total, i32 noundef %n) #8, !dbg !202
    #dbg_value(i32 0, !203, !DIExpression(), !205)
  br label %for.cond, !dbg !206

for.cond:                                         ; preds = %for.body, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ], !dbg !207
    #dbg_value(i32 %i.0, !203, !DIExpression(), !205)
  %cmp1 = icmp slt i32 %i.0, %n., !dbg !208
  br i1 %cmp1, label %for.body, label %for.end, !dbg !210

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !211
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !211
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !213
  %0 = load i32, ptr %count, align 4, !dbg !213
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.6, ptr noundef %arrayidx, i32 noundef %0) #8, !dbg !214
  %1 = load i32, ptr %count, align 4, !dbg !215
  %count9 = getelementptr inbounds nuw i8, ptr %entries, i64 24, !dbg !216
  %2 = load i32, ptr %count9, align 4, !dbg !216
  call void @print_bar(i32 noundef %1, i32 noundef %2), !dbg !217
  %inc = add nuw nsw i32 %i.0, 1, !dbg !218
    #dbg_value(i32 %inc, !203, !DIExpression(), !205)
  br label %for.cond, !dbg !219, !llvm.loop !220

for.end:                                          ; preds = %for.cond
  %call11 = call ptr @longest(ptr noundef %entries, i32 noundef %n), !dbg !222
    #dbg_value(ptr %call11, !223, !DIExpression(), !197)
  %cmp12.not = icmp eq ptr %call11, null, !dbg !224
  br i1 %cmp12.not, label %if.end, label %if.then, !dbg !224

if.then:                                          ; preds = %for.end
  %call15 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.7, ptr noundef nonnull %call11) #8, !dbg !226
  br label %if.end, !dbg !228

if.end:                                           ; preds = %if.then, %for.end
  %call16 = call double @mean_length(ptr noundef %entries, i32 noundef %n), !dbg !229
  %call17 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.8, double noundef %call16) #8, !dbg !230
  %call18 = call i32 @singletons(ptr noundef %entries, i32 noundef %n), !dbg !231
  %call19 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.9, i32 noundef %call18) #8, !dbg !232
  ret void, !dbg !233
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_lookup(ptr noundef %table, ptr noundef %word) #0 !dbg !234 {
entry:
    #dbg_value(ptr %table, !237, !DIExpression(), !238)
    #dbg_value(ptr %word, !239, !DIExpression(), !238)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !240
    #dbg_value(i32 %call, !241, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !238)
    #dbg_value(i32 0, !242, !DIExpression(), !244)
  br label %for.cond, !dbg !245

for.cond:                                         ; preds = %for.inc, %entry
  %index.0.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !246
  %index.0 = and i32 %index.0.in, 255, !dbg !238
    #dbg_value(i32 %probe.0, !242, !DIExpression(), !244)
    #dbg_value(i32 %index.0, !241, !DIExpression(), !238)
  %cmp = icmp samesign ult i32 %probe.0, 256, !dbg !247
  br i1 %cmp, label %for.body, label %return, !dbg !249

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %index.0 to i64, !dbg !250
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !250
    #dbg_value(ptr %arrayidx, !252, !DIExpression(), !253)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !254
  %0 = load i32, ptr %count, align 4, !dbg !254
  %cmp1 = icmp eq i32 %0, 0, !dbg !256
  br i1 %cmp1, label %return, label %if.end, !dbg !256

if.end:                                           ; preds = %for.body
  %call3 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #10, !dbg !257
  %cmp4 = icmp eq i32 %call3, 0, !dbg !259
  br i1 %cmp4, label %return, label %for.inc, !dbg !259

for.inc:                                          ; preds = %if.end
    #dbg_value(i32 poison, !241, !DIExpression(), !238)
  %add = add nuw nsw i32 %index.0, 1, !dbg !260
    #dbg_value(i32 %add, !241, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !238)
  %inc = add nuw nsw i32 %probe.0, 1, !dbg !261
    #dbg_value(i32 %inc, !242, !DIExpression(), !244)
  br label %for.cond, !dbg !262, !llvm.loop !263

return:                                           ; preds = %if.end, %for.body, %for.cond
  %retval.0 = phi i32 [ 0, %for.body ], [ 0, %for.cond ], [ %0, %if.end ], !dbg !238
  ret i32 %retval.0, !dbg !265
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind uwtable
define internal i32 @next_word(ptr noundef %text, ptr noundef %word) #0 !dbg !266 {
entry:
    #dbg_value(ptr %text, !271, !DIExpression(), !272)
    #dbg_value(ptr %word, !273, !DIExpression(), !272)
  %0 = load ptr, ptr %text, align 8, !dbg !274
    #dbg_value(ptr %0, !275, !DIExpression(), !272)
  br label %while.cond, !dbg !276

while.cond:                                       ; preds = %while.body, %entry
  %p.0 = phi ptr [ %0, %entry ], [ %incdec.ptr, %while.body ], !dbg !272
    #dbg_value(ptr %p.0, !275, !DIExpression(), !272)
  %1 = load i8, ptr %p.0, align 1, !dbg !277
  %cmp.not = icmp eq i8 %1, 0, !dbg !278
  br i1 %cmp.not, label %while.end, label %land.rhs, !dbg !279

land.rhs:                                         ; preds = %while.cond
  %call = call ptr @__ctype_b_loc() #11, !dbg !280
  %2 = load ptr, ptr %call, align 8, !dbg !280
  %idxprom = zext i8 %1 to i64, !dbg !280
  %arrayidx = getelementptr inbounds nuw i16, ptr %2, i64 %idxprom, !dbg !280
  %3 = load i16, ptr %arrayidx, align 2, !dbg !280
  %4 = and i16 %3, 1024, !dbg !280
  %tobool.not = icmp eq i16 %4, 0, !dbg !281
  br i1 %tobool.not, label %while.body, label %while.end, !dbg !276

while.body:                                       ; preds = %land.rhs
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !282
    #dbg_value(ptr %incdec.ptr, !275, !DIExpression(), !272)
  br label %while.cond, !dbg !276, !llvm.loop !284

while.end:                                        ; preds = %land.rhs, %while.cond
  %p.0.lcssa = phi ptr [ %p.0, %land.rhs ], [ %p.0, %while.cond ], !dbg !272
  %.lcssa = phi i8 [ %1, %land.rhs ], [ %1, %while.cond ], !dbg !277
    #dbg_value(i32 0, !286, !DIExpression(), !272)
  br label %while.cond4, !dbg !287

while.cond4:                                      ; preds = %if.end, %while.end
  %5 = phi i8 [ %.lcssa, %while.end ], [ %.pre, %if.end ], !dbg !288
  %p.1 = phi ptr [ %p.0.lcssa, %while.end ], [ %incdec.ptr20, %if.end ], !dbg !272
  %length.0 = phi i32 [ 0, %while.end ], [ %length.1, %if.end ], !dbg !272
    #dbg_value(i32 %length.0, !286, !DIExpression(), !272)
    #dbg_value(ptr %p.1, !275, !DIExpression(), !272)
  %call5 = call ptr @__ctype_b_loc() #11, !dbg !289
  %6 = load ptr, ptr %call5, align 8, !dbg !289
  %idxprom7 = zext i8 %5 to i64, !dbg !289
  %arrayidx8 = getelementptr inbounds nuw i16, ptr %6, i64 %idxprom7, !dbg !289
  %7 = load i16, ptr %arrayidx8, align 2, !dbg !289
  %8 = and i16 %7, 1024, !dbg !289
  %tobool11.not = icmp eq i16 %8, 0, !dbg !287
  br i1 %tobool11.not, label %while.end21, label %while.body12, !dbg !287

while.body12:                                     ; preds = %while.cond4
  %cmp13 = icmp slt i32 %length.0, 23, !dbg !290
  br i1 %cmp13, label %if.then, label %if.end, !dbg !290

if.then:                                          ; preds = %while.body12
  %conv15 = zext i8 %5 to i32, !dbg !293
  %call16 = call i32 @tolower(i32 noundef %conv15) #10, !dbg !295
  %conv17 = trunc i32 %call16 to i8, !dbg !296
  %inc = add nsw i32 %length.0, 1, !dbg !297
    #dbg_value(i32 %inc, !286, !DIExpression(), !272)
  %idxprom18 = sext i32 %length.0 to i64, !dbg !298
  %arrayidx19 = getelementptr inbounds i8, ptr %word, i64 %idxprom18, !dbg !298
  store i8 %conv17, ptr %arrayidx19, align 1, !dbg !299
  br label %if.end, !dbg !300

if.end:                                           ; preds = %if.then, %while.body12
  %length.1 = phi i32 [ %inc, %if.then ], [ %length.0, %while.body12 ], !dbg !272
    #dbg_value(i32 %length.1, !286, !DIExpression(), !272)
  %incdec.ptr20 = getelementptr inbounds nuw i8, ptr %p.1, i64 1, !dbg !301
    #dbg_value(ptr %incdec.ptr20, !275, !DIExpression(), !272)
  %.pre = load i8, ptr %incdec.ptr20, align 1, !dbg !288
  br label %while.cond4, !dbg !287, !llvm.loop !302

while.end21:                                      ; preds = %while.cond4
  %p.1.lcssa = phi ptr [ %p.1, %while.cond4 ], !dbg !272
  %length.0.lcssa = phi i32 [ %length.0, %while.cond4 ], !dbg !272
  %idxprom22 = sext i32 %length.0.lcssa to i64, !dbg !304
  %arrayidx23 = getelementptr inbounds i8, ptr %word, i64 %idxprom22, !dbg !304
  store i8 0, ptr %arrayidx23, align 1, !dbg !305
  store ptr %p.1.lcssa, ptr %text, align 8, !dbg !306
  ret i32 %length.0.lcssa, !dbg !307
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_add(ptr noundef %table, ptr noundef %word, i32 noundef %position) #0 !dbg !308 {
entry:
    #dbg_value(ptr %table, !311, !DIExpression(), !312)
    #dbg_value(ptr %word, !313, !DIExpression(), !312)
    #dbg_value(i32 %position, !314, !DIExpression(), !312)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !315
    #dbg_value(i32 %call, !316, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !312)
    #dbg_value(i32 0, !317, !DIExpression(), !319)
  br label %for.cond, !dbg !320

for.cond:                                         ; preds = %for.inc, %entry
  %index.0.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.0 = phi i32 [ 0, %entry ], [ %inc14, %for.inc ], !dbg !321
  %index.0 = and i32 %index.0.in, 255, !dbg !312
    #dbg_value(i32 %probe.0, !317, !DIExpression(), !319)
    #dbg_value(i32 %index.0, !316, !DIExpression(), !312)
  %cmp = icmp samesign ult i32 %probe.0, 256, !dbg !322
  br i1 %cmp, label %for.body, label %return.loopexit, !dbg !324

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %index.0 to i64, !dbg !325
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !325
    #dbg_value(ptr %arrayidx, !327, !DIExpression(), !328)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !329
  %0 = load i32, ptr %count, align 4, !dbg !329
  %cmp1 = icmp eq i32 %0, 0, !dbg !331
  br i1 %cmp1, label %if.then, label %if.end, !dbg !331

if.then:                                          ; preds = %for.body
  %arrayidx.lcssa = phi ptr [ %arrayidx, %for.body ], !dbg !325
  %count.lcssa = phi ptr [ %count, %for.body ], !dbg !329
  %call3 = call ptr @strncpy(ptr noundef nonnull dereferenceable(1) %arrayidx.lcssa, ptr noundef nonnull dereferenceable(1) %word, i64 noundef 23) #8, !dbg !332
  store i32 1, ptr %count.lcssa, align 4, !dbg !334
  %first_seen = getelementptr inbounds nuw i8, ptr %arrayidx.lcssa, i64 28, !dbg !335
  store i32 %position, ptr %first_seen, align 4, !dbg !336
  %used = getelementptr inbounds nuw i8, ptr %table, i64 8192, !dbg !337
  %1 = load i32, ptr %used, align 4, !dbg !338
  %inc = add nsw i32 %1, 1, !dbg !338
  store i32 %inc, ptr %used, align 4, !dbg !338
  br label %return, !dbg !339

if.end:                                           ; preds = %for.body
  %call7 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #10, !dbg !340
  %cmp8 = icmp eq i32 %call7, 0, !dbg !342
  br i1 %cmp8, label %if.then9, label %for.inc, !dbg !342

if.then9:                                         ; preds = %if.end
  %count.lcssa2 = phi ptr [ %count, %if.end ], !dbg !329
  %.lcssa1 = phi i32 [ %0, %if.end ], !dbg !329
  %inc11 = add nsw i32 %.lcssa1, 1, !dbg !343
  store i32 %inc11, ptr %count.lcssa2, align 4, !dbg !343
  br label %return, !dbg !345

for.inc:                                          ; preds = %if.end
    #dbg_value(i32 poison, !316, !DIExpression(), !312)
  %add = add nuw nsw i32 %index.0, 1, !dbg !346
    #dbg_value(i32 %add, !316, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !312)
  %inc14 = add nuw nsw i32 %probe.0, 1, !dbg !347
    #dbg_value(i32 %inc14, !317, !DIExpression(), !319)
  br label %for.cond, !dbg !348, !llvm.loop !349

return.loopexit:                                  ; preds = %for.cond
  br label %return, !dbg !351

return:                                           ; preds = %return.loopexit, %if.then9, %if.then
  %retval.0 = phi i32 [ 1, %if.then ], [ 0, %if.then9 ], [ -1, %return.loopexit ], !dbg !312
  ret i32 %retval.0, !dbg !351
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #4

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #5

; Function Attrs: noinline nounwind uwtable
define internal i32 @hash_word(ptr noundef %word) #0 !dbg !352 {
entry:
    #dbg_value(ptr %word, !355, !DIExpression(), !356)
    #dbg_value(i32 -2128831035, !357, !DIExpression(), !356)
    #dbg_value(ptr %word, !358, !DIExpression(), !360)
  br label %for.cond, !dbg !361

for.cond:                                         ; preds = %for.inc, %entry
  %hash.0 = phi i32 [ -2128831035, %entry ], [ %mul, %for.inc ], !dbg !356
  %p.0 = phi ptr [ %word, %entry ], [ %incdec.ptr, %for.inc ], !dbg !362
    #dbg_value(ptr %p.0, !358, !DIExpression(), !360)
    #dbg_value(i32 %hash.0, !357, !DIExpression(), !356)
  %0 = load i8, ptr %p.0, align 1, !dbg !363
  %cmp.not = icmp eq i8 %0, 0, !dbg !365
  br i1 %cmp.not, label %for.end, label %for.inc, !dbg !366

for.inc:                                          ; preds = %for.cond
    #dbg_value(!DIArgList(i32 poison, i8 poison), !357, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_stack_value), !356)
    #dbg_value(!DIArgList(i32 poison, i8 poison), !357, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !356)
    #dbg_value(!DIArgList(i32 %hash.0, i8 %0), !357, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !356)
  %conv2 = zext i8 %0 to i32, !dbg !367
    #dbg_value(!DIArgList(i32 %hash.0, i32 %conv2), !357, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !356)
  %xor = xor i32 %hash.0, %conv2, !dbg !369
    #dbg_value(i32 %xor, !357, !DIExpression(DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !356)
  %mul = mul i32 %xor, 16777619, !dbg !370
    #dbg_value(i32 %mul, !357, !DIExpression(), !356)
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !371
    #dbg_value(ptr %incdec.ptr, !358, !DIExpression(), !360)
  br label %for.cond, !dbg !372, !llvm.loop !373

for.end:                                          ; preds = %for.cond
  %hash.0.lcssa = phi i32 [ %hash.0, %for.cond ], !dbg !356
  ret i32 %hash.0.lcssa, !dbg !375
}

; Function Attrs: nounwind
declare ptr @strncpy(ptr noundef, ptr noundef, i64 noundef) #3

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #6

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define internal i32 @by_count(ptr noundef %a, ptr noundef %b) #0 !dbg !376 {
entry:
    #dbg_value(ptr %a, !381, !DIExpression(), !382)
    #dbg_value(ptr %b, !383, !DIExpression(), !382)
    #dbg_value(ptr %a, !384, !DIExpression(), !382)
    #dbg_value(ptr %b, !385, !DIExpression(), !382)
  %count = getelementptr inbounds nuw i8, ptr %a, i64 24, !dbg !386
  %0 = load i32, ptr %count, align 4, !dbg !386
  %count1 = getelementptr inbounds nuw i8, ptr %b, i64 24, !dbg !388
  %1 = load i32, ptr %count1, align 4, !dbg !388
  %cmp.not = icmp eq i32 %0, %1, !dbg !389
  br i1 %cmp.not, label %if.end, label %if.then, !dbg !389

if.then:                                          ; preds = %entry
  %sub = sub nsw i32 %1, %0, !dbg !390
  br label %return, !dbg !392

if.end:                                           ; preds = %entry
  %first_seen = getelementptr inbounds nuw i8, ptr %a, i64 28, !dbg !393
  %2 = load i32, ptr %first_seen, align 4, !dbg !393
  %first_seen4 = getelementptr inbounds nuw i8, ptr %b, i64 28, !dbg !394
  %3 = load i32, ptr %first_seen4, align 4, !dbg !394
  %sub5 = sub nsw i32 %2, %3, !dbg !395
  br label %return, !dbg !396

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ %sub, %if.then ], [ %sub5, %if.end ], !dbg !382
  ret i32 %retval.0, !dbg !397
}

; Function Attrs: noinline nounwind uwtable
define internal void @print_bar(i32 noundef %count, i32 noundef %widest) #0 !dbg !398 {
entry:
    #dbg_value(i32 %count, !401, !DIExpression(), !402)
    #dbg_value(i32 %widest, !403, !DIExpression(), !402)
  %cmp = icmp sgt i32 %widest, 0, !dbg !404
  br i1 %cmp, label %cond.true, label %cond.end, !dbg !405

cond.true:                                        ; preds = %entry
  %mul = mul nsw i32 %count, 30, !dbg !406
  %div = sdiv i32 %mul, %widest, !dbg !407
  br label %cond.end, !dbg !405

cond.end:                                         ; preds = %cond.true, %entry
  %cond = phi i32 [ %div, %cond.true ], [ 0, %entry ], !dbg !405
    #dbg_value(i32 %cond, !408, !DIExpression(), !402)
    #dbg_value(i32 0, !409, !DIExpression(), !411)
  br label %for.cond, !dbg !412

for.cond:                                         ; preds = %for.body, %cond.end
  %i.0 = phi i32 [ 0, %cond.end ], [ %inc, %for.body ], !dbg !413
    #dbg_value(i32 %i.0, !409, !DIExpression(), !411)
  %cmp1 = icmp slt i32 %i.0, %cond, !dbg !414
  br i1 %cmp1, label %for.body, label %for.end, !dbg !416

for.body:                                         ; preds = %for.cond
  %call = call i32 @putchar(i32 noundef 35) #8, !dbg !417
  %inc = add nuw nsw i32 %i.0, 1, !dbg !419
    #dbg_value(i32 %inc, !409, !DIExpression(), !411)
  br label %for.cond, !dbg !420, !llvm.loop !421

for.end:                                          ; preds = %for.cond
  %call2 = call i32 @putchar(i32 noundef 10) #8, !dbg !423
  ret void, !dbg !424
}

; Function Attrs: noinline nounwind uwtable
define internal ptr @longest(ptr noundef %entries, i32 noundef %n) #0 !dbg !425 {
entry:
    #dbg_value(ptr %entries, !428, !DIExpression(), !429)
    #dbg_value(i32 %n, !430, !DIExpression(), !429)
    #dbg_value(ptr null, !431, !DIExpression(), !429)
    #dbg_value(i64 0, !432, !DIExpression(), !429)
    #dbg_value(i32 0, !433, !DIExpression(), !435)
  br label %for.cond, !dbg !436

for.cond:                                         ; preds = %for.body, %entry
  %best.0 = phi ptr [ null, %entry ], [ %best.1, %for.body ], !dbg !429
  %best_length.0 = phi i64 [ 0, %entry ], [ %best_length.1, %for.body ], !dbg !429
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ], !dbg !437
    #dbg_value(i32 %i.0, !433, !DIExpression(), !435)
    #dbg_value(i64 %best_length.0, !432, !DIExpression(), !429)
    #dbg_value(ptr %best.0, !431, !DIExpression(), !429)
  %cmp = icmp slt i32 %i.0, %n, !dbg !438
  br i1 %cmp, label %for.body, label %for.end, !dbg !440

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !441
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !441
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx) #10, !dbg !443
    #dbg_value(i64 %call, !444, !DIExpression(), !445)
  %cmp1 = icmp ugt i64 %call, %best_length.0, !dbg !446
  %best.1 = select i1 %cmp1, ptr %arrayidx, ptr %best.0, !dbg !446
  %best_length.1 = call i64 @llvm.umax.i64(i64 %call, i64 %best_length.0), !dbg !446
    #dbg_value(i64 %best_length.1, !432, !DIExpression(), !429)
    #dbg_value(ptr %best.1, !431, !DIExpression(), !429)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !448
    #dbg_value(i32 %inc, !433, !DIExpression(), !435)
  br label %for.cond, !dbg !449, !llvm.loop !450

for.end:                                          ; preds = %for.cond
  %best.0.lcssa = phi ptr [ %best.0, %for.cond ], !dbg !429
  ret ptr %best.0.lcssa, !dbg !452
}

; Function Attrs: noinline nounwind uwtable
define internal double @mean_length(ptr noundef %entries, i32 noundef %n) #0 !dbg !453 {
entry:
    #dbg_value(ptr %entries, !456, !DIExpression(), !457)
    #dbg_value(i32 %n, !458, !DIExpression(), !457)
    #dbg_value(i64 0, !459, !DIExpression(), !457)
    #dbg_value(i64 0, !460, !DIExpression(), !457)
    #dbg_value(i32 0, !461, !DIExpression(), !463)
  br label %for.cond, !dbg !464

for.cond:                                         ; preds = %for.inc, %entry
  %letters.0 = phi i64 [ 0, %entry ], [ %add, %for.inc ], !dbg !457
  %words.0 = phi i64 [ 0, %entry ], [ %add7, %for.inc ], !dbg !457
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !465
    #dbg_value(i32 %i.0, !461, !DIExpression(), !463)
    #dbg_value(i64 %words.0, !460, !DIExpression(), !457)
    #dbg_value(i64 %letters.0, !459, !DIExpression(), !457)
  %cmp = icmp slt i32 %i.0, %n, !dbg !466
  br i1 %cmp, label %for.inc, label %for.end, !dbg !468

for.inc:                                          ; preds = %for.cond
    #dbg_value(!DIArgList(i64 poison, i64 poison, i32 poison), !459, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !457)
    #dbg_value(!DIArgList(i64 poison, i32 poison), !460, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !457)
  %idxprom3 = zext nneg i32 %i.0 to i64, !dbg !469
  %arrayidx4 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom3, !dbg !469
  %count5 = getelementptr inbounds nuw i8, ptr %arrayidx4, i64 24, !dbg !471
  %0 = load i32, ptr %count5, align 4, !dbg !471
    #dbg_value(!DIArgList(i64 %words.0, i32 %0), !460, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !457)
  %conv6 = sext i32 %0 to i64, !dbg !469
    #dbg_value(!DIArgList(i64 %words.0, i64 %conv6), !460, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !457)
  %add7 = add nsw i64 %words.0, %conv6, !dbg !472
    #dbg_value(i64 %add7, !460, !DIExpression(), !457)
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx4) #10, !dbg !473
    #dbg_value(!DIArgList(i64 %letters.0, i64 %call, i32 %0), !459, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !457)
    #dbg_value(!DIArgList(i64 %letters.0, i64 %call, i64 %conv6), !459, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !457)
  %mul = mul nsw i64 %call, %conv6, !dbg !474
    #dbg_value(!DIArgList(i64 %letters.0, i64 %mul), !459, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !457)
  %add = add nsw i64 %letters.0, %mul, !dbg !475
    #dbg_value(i64 %add, !459, !DIExpression(), !457)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !476
    #dbg_value(i32 %inc, !461, !DIExpression(), !463)
  br label %for.cond, !dbg !477, !llvm.loop !478

for.end:                                          ; preds = %for.cond
  %letters.0.lcssa = phi i64 [ %letters.0, %for.cond ], !dbg !457
  %words.0.lcssa = phi i64 [ %words.0, %for.cond ], !dbg !457
  %cmp8 = icmp sgt i64 %words.0.lcssa, 0, !dbg !480
  %conv10 = sitofp i64 %letters.0.lcssa to double, !dbg !481
  %conv11 = sitofp i64 %words.0.lcssa to double, !dbg !481
  %div = fdiv double %conv10, %conv11, !dbg !481
  %cond = select i1 %cmp8, double %div, double 0.000000e+00, !dbg !481
  ret double %cond, !dbg !482
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @singletons(ptr noundef %entries, i32 noundef %n) #0 !dbg !483 {
entry:
    #dbg_value(ptr %entries, !486, !DIExpression(), !487)
    #dbg_value(i32 %n, !488, !DIExpression(), !487)
    #dbg_value(i32 0, !489, !DIExpression(), !487)
    #dbg_value(i32 %n, !490, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !492)
  br label %for.cond, !dbg !493

for.cond:                                         ; preds = %for.inc, %entry
  %count.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !487
  %i.0.in = phi i32 [ %n, %entry ], [ %i.0, %for.inc ]
  %i.0 = add nsw i32 %i.0.in, -1, !dbg !494
    #dbg_value(i32 %i.0, !490, !DIExpression(), !492)
    #dbg_value(i32 %count.0, !489, !DIExpression(), !487)
  %cmp = icmp sgt i32 %i.0.in, 0, !dbg !495
  br i1 %cmp, label %land.rhs, label %for.end, !dbg !497

land.rhs:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !498
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom, !dbg !498
  %count1 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !499
  %0 = load i32, ptr %count1, align 4, !dbg !499
  %cmp2 = icmp eq i32 %0, 1, !dbg !500
  br i1 %cmp2, label %for.inc, label %for.end, !dbg !501

for.inc:                                          ; preds = %land.rhs
    #dbg_value(i32 %count.0, !489, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !487)
  %inc = add nuw nsw i32 %count.0, 1, !dbg !502
    #dbg_value(i32 %inc, !489, !DIExpression(), !487)
    #dbg_value(i32 %i.0, !490, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !492)
  br label %for.cond, !dbg !504, !llvm.loop !505

for.end:                                          ; preds = %land.rhs, %for.cond
  %count.0.lcssa = phi i32 [ %count.0, %land.rhs ], [ %count.0, %for.cond ], !dbg !487
  ret i32 %count.0.lcssa, !dbg !507
}

declare i32 @putchar(i32 noundef) #1

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #5

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umax.i64(i64, i64) #7

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nounwind }
attributes #9 = { cold nounwind }
attributes #10 = { nounwind willreturn memory(read) }
attributes #11 = { nounwind willreturn memory(none) }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!100, !101, !102, !103, !104, !105, !106}
!llvm.ident = !{!107}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "table", scope: !2, file: !3, line: 186, type: !96, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 185, type: !4, scopeLine: 185, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !7, retainedNodes: !95)
!3 = !DIFile(filename: "user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!4 = !DISubroutineType(types: !5)
!5 = !{!6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !9, retainedTypes: !26, globals: !36, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/workspace/user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!9 = !{!10}
!10 = !DICompositeType(tag: DW_TAG_enumeration_type, file: !11, line: 46, baseType: !12, size: 32, elements: !13)
!11 = !DIFile(filename: "/usr/include/ctype.h", directory: "", checksumkind: CSK_MD5, checksum: "43fd45dcf96e8fb7d8f14700096497c7")
!12 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!13 = !{!14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25}
!14 = !DIEnumerator(name: "_ISupper", value: 256)
!15 = !DIEnumerator(name: "_ISlower", value: 512)
!16 = !DIEnumerator(name: "_ISalpha", value: 1024)
!17 = !DIEnumerator(name: "_ISdigit", value: 2048)
!18 = !DIEnumerator(name: "_ISxdigit", value: 4096)
!19 = !DIEnumerator(name: "_ISspace", value: 8192)
!20 = !DIEnumerator(name: "_ISprint", value: 16384)
!21 = !DIEnumerator(name: "_ISgraph", value: 32768)
!22 = !DIEnumerator(name: "_ISblank", value: 1)
!23 = !DIEnumerator(name: "_IScntrl", value: 2)
!24 = !DIEnumerator(name: "_ISpunct", value: 4)
!25 = !DIEnumerator(name: "_ISalnum", value: 8)
!26 = !{!6, !27, !28, !29, !30, !33, !34, !35}
!27 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!28 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!29 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!30 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !31, line: 18, baseType: !32)
!31 = !DIFile(filename: "/opt/llvm/lib/clang/22/include/__stddef_size_t.h", directory: "", checksumkind: CSK_MD5, checksum: "2c44e821a2b1951cde2eb0fb2e656867")
!32 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!33 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!34 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !{!0, !37, !50, !55, !57, !62, !67, !72, !76, !78, !83, !85, !90}
!37 = !DIGlobalVariableExpression(var: !38, expr: !DIExpression())
!38 = distinct !DIGlobalVariable(name: "entries", scope: !2, file: !3, line: 187, type: !39, isLocal: true, isDefinition: true)
!39 = !DICompositeType(tag: DW_TAG_array_type, baseType: !40, size: 65536, elements: !48)
!40 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "entry", file: !3, line: 12, size: 256, elements: !41)
!41 = !{!42, !46, !47}
!42 = !DIDerivedType(tag: DW_TAG_member, name: "word", scope: !40, file: !3, line: 13, baseType: !43, size: 192)
!43 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 192, elements: !44)
!44 = !{!45}
!45 = !DISubrange(count: 24)
!46 = !DIDerivedType(tag: DW_TAG_member, name: "count", scope: !40, file: !3, line: 14, baseType: !6, size: 32, offset: 192)
!47 = !DIDerivedType(tag: DW_TAG_member, name: "first_seen", scope: !40, file: !3, line: 15, baseType: !6, size: 32, offset: 224)
!48 = !{!49}
!49 = !DISubrange(count: 256)
!50 = !DIGlobalVariableExpression(var: !51, expr: !DIExpression())
!51 = distinct !DIGlobalVariable(scope: null, file: !3, line: 192, type: !52, isLocal: true, isDefinition: true)
!52 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 32, elements: !53)
!53 = !{!54}
!54 = !DISubrange(count: 4)
!55 = !DIGlobalVariableExpression(var: !56, expr: !DIExpression())
!56 = distinct !DIGlobalVariable(scope: null, file: !3, line: 193, type: !52, isLocal: true, isDefinition: true)
!57 = !DIGlobalVariableExpression(var: !58, expr: !DIExpression())
!58 = distinct !DIGlobalVariable(scope: null, file: !3, line: 194, type: !59, isLocal: true, isDefinition: true)
!59 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 144, elements: !60)
!60 = !{!61}
!61 = !DISubrange(count: 18)
!62 = !DIGlobalVariableExpression(var: !63, expr: !DIExpression())
!63 = distinct !DIGlobalVariable(scope: null, file: !3, line: 102, type: !64, isLocal: true, isDefinition: true)
!64 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 184, elements: !65)
!65 = !{!66}
!66 = !DISubrange(count: 23)
!67 = !DIGlobalVariableExpression(var: !68, expr: !DIExpression())
!68 = distinct !DIGlobalVariable(scope: null, file: !3, line: 24, type: !69, isLocal: true, isDefinition: true)
!69 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 2280, elements: !70)
!70 = !{!71}
!71 = !DISubrange(count: 285)
!72 = !DIGlobalVariableExpression(var: !73, expr: !DIExpression())
!73 = distinct !DIGlobalVariable(name: "passage", scope: !7, file: !3, line: 23, type: !74, isLocal: true, isDefinition: true)
!74 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !75, size: 64)
!75 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !29)
!76 = !DIGlobalVariableExpression(var: !77, expr: !DIExpression())
!77 = distinct !DIGlobalVariable(scope: null, file: !3, line: 172, type: !64, isLocal: true, isDefinition: true)
!78 = !DIGlobalVariableExpression(var: !79, expr: !DIExpression())
!79 = distinct !DIGlobalVariable(scope: null, file: !3, line: 174, type: !80, isLocal: true, isDefinition: true)
!80 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 88, elements: !81)
!81 = !{!82}
!82 = !DISubrange(count: 11)
!83 = !DIGlobalVariableExpression(var: !84, expr: !DIExpression())
!84 = distinct !DIGlobalVariable(scope: null, file: !3, line: 179, type: !59, isLocal: true, isDefinition: true)
!85 = !DIGlobalVariableExpression(var: !86, expr: !DIExpression())
!86 = distinct !DIGlobalVariable(scope: null, file: !3, line: 181, type: !87, isLocal: true, isDefinition: true)
!87 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 216, elements: !88)
!88 = !{!89}
!89 = !DISubrange(count: 27)
!90 = !DIGlobalVariableExpression(var: !91, expr: !DIExpression())
!91 = distinct !DIGlobalVariable(scope: null, file: !3, line: 182, type: !92, isLocal: true, isDefinition: true)
!92 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 168, elements: !93)
!93 = !{!94}
!94 = !DISubrange(count: 21)
!95 = !{}
!96 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "table", file: !3, line: 18, size: 65568, elements: !97)
!97 = !{!98, !99}
!98 = !DIDerivedType(tag: DW_TAG_member, name: "slots", scope: !96, file: !3, line: 19, baseType: !39, size: 65536)
!99 = !DIDerivedType(tag: DW_TAG_member, name: "used", scope: !96, file: !3, line: 20, baseType: !6, size: 32, offset: 65536)
!100 = !{i32 7, !"Dwarf Version", i32 5}
!101 = !{i32 2, !"Debug Info Version", i32 3}
!102 = !{i32 1, !"wchar_size", i32 4}
!103 = !{i32 8, !"PIC Level", i32 2}
!104 = !{i32 7, !"PIE Level", i32 2}
!105 = !{i32 7, !"uwtable", i32 2}
!106 = !{i32 7, !"frame-pointer", i32 2}
!107 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!108 = !DILocation(line: 188, column: 5, scope: !2)
!109 = !DILocation(line: 189, column: 37, scope: !2)
!110 = !DILocation(line: 189, column: 17, scope: !2)
!111 = !DILocalVariable(name: "total", scope: !2, file: !3, line: 189, type: !6)
!112 = !DILocation(line: 0, scope: !2)
!113 = !DILocation(line: 190, column: 13, scope: !2)
!114 = !DILocalVariable(name: "n", scope: !2, file: !3, line: 190, type: !6)
!115 = !DILocation(line: 191, column: 5, scope: !2)
!116 = !DILocation(line: 192, column: 17, scope: !2)
!117 = !DILocalVariable(name: "foxes", scope: !2, file: !3, line: 192, type: !6)
!118 = !DILocation(line: 193, column: 16, scope: !2)
!119 = !DILocalVariable(name: "cats", scope: !2, file: !3, line: 193, type: !6)
!120 = !DILocation(line: 194, column: 5, scope: !2)
!121 = !DILocation(line: 195, column: 22, scope: !2)
!122 = !DILocation(line: 195, column: 5, scope: !2)
!123 = distinct !DISubprogram(name: "table_init", scope: !3, file: !3, line: 39, type: !124, scopeLine: 39, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!124 = !DISubroutineType(types: !125)
!125 = !{null, !126}
!126 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !96, size: 64)
!127 = !DILocalVariable(name: "table", arg: 1, scope: !123, file: !3, line: 39, type: !126)
!128 = !DILocation(line: 0, scope: !123)
!129 = !DILocation(line: 40, column: 5, scope: !123)
!130 = !DILocation(line: 41, column: 1, scope: !123)
!131 = distinct !DISubprogram(name: "count_words", scope: !3, file: !3, line: 97, type: !132, scopeLine: 97, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!132 = !DISubroutineType(types: !133)
!133 = !{!6, !126, !74}
!134 = !DILocalVariable(name: "table", arg: 1, scope: !131, file: !3, line: 97, type: !126)
!135 = !DILocation(line: 0, scope: !131)
!136 = !DILocalVariable(name: "text", arg: 2, scope: !131, file: !3, line: 97, type: !74)
!137 = !DILocalVariable(name: "word", scope: !131, file: !3, line: 98, type: !43)
!138 = !DILocation(line: 98, column: 10, scope: !131)
!139 = !DILocalVariable(name: "position", scope: !131, file: !3, line: 99, type: !6)
!140 = !DILocation(line: 100, column: 5, scope: !131)
!141 = !DILocation(line: 100, column: 12, scope: !131)
!142 = !DILocation(line: 100, column: 35, scope: !131)
!143 = !DILocation(line: 101, column: 13, scope: !144)
!144 = distinct !DILexicalBlock(scope: !145, file: !3, line: 101, column: 13)
!145 = distinct !DILexicalBlock(scope: !131, file: !3, line: 100, column: 40)
!146 = !DILocation(line: 101, column: 46, scope: !144)
!147 = !DILocation(line: 102, column: 21, scope: !148)
!148 = distinct !DILexicalBlock(scope: !144, file: !3, line: 101, column: 51)
!149 = !DILocation(line: 102, column: 13, scope: !148)
!150 = !DILocation(line: 103, column: 13, scope: !148)
!151 = !DILocation(line: 105, column: 17, scope: !145)
!152 = distinct !{!152, !140, !153, !154}
!153 = !DILocation(line: 106, column: 5, scope: !131)
!154 = !{!"llvm.loop.mustprogress"}
!155 = !DILocation(line: 107, column: 5, scope: !131)
!156 = distinct !DISubprogram(name: "collect", scope: !3, file: !3, line: 120, type: !157, scopeLine: 120, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!157 = !DISubroutineType(types: !158)
!158 = !{!6, !159, !161}
!159 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !160, size: 64)
!160 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !96)
!161 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!162 = !DILocalVariable(name: "table", arg: 1, scope: !156, file: !3, line: 120, type: !159)
!163 = !DILocation(line: 0, scope: !156)
!164 = !DILocalVariable(name: "out", arg: 2, scope: !156, file: !3, line: 120, type: !161)
!165 = !DILocalVariable(name: "n", scope: !156, file: !3, line: 121, type: !6)
!166 = !DILocalVariable(name: "i", scope: !167, file: !3, line: 122, type: !6)
!167 = distinct !DILexicalBlock(scope: !156, file: !3, line: 122, column: 5)
!168 = !DILocation(line: 0, scope: !167)
!169 = !DILocation(line: 122, column: 10, scope: !167)
!170 = !DILocation(line: 122, scope: !167)
!171 = !DILocation(line: 122, column: 23, scope: !172)
!172 = distinct !DILexicalBlock(scope: !167, file: !3, line: 122, column: 5)
!173 = !DILocation(line: 122, column: 5, scope: !167)
!174 = !DILocation(line: 123, column: 13, scope: !175)
!175 = distinct !DILexicalBlock(scope: !176, file: !3, line: 123, column: 13)
!176 = distinct !DILexicalBlock(scope: !172, file: !3, line: 122, column: 42)
!177 = !DILocation(line: 123, column: 29, scope: !175)
!178 = !DILocation(line: 123, column: 35, scope: !175)
!179 = !DILocation(line: 124, column: 18, scope: !180)
!180 = distinct !DILexicalBlock(scope: !175, file: !3, line: 123, column: 40)
!181 = !DILocation(line: 124, column: 13, scope: !180)
!182 = !DILocation(line: 124, column: 24, scope: !180)
!183 = !DILocation(line: 125, column: 9, scope: !180)
!184 = !DILocation(line: 122, column: 38, scope: !172)
!185 = !DILocation(line: 122, column: 5, scope: !172)
!186 = distinct !{!186, !173, !187, !154}
!187 = !DILocation(line: 126, column: 5, scope: !167)
!188 = !DILocation(line: 127, column: 16, scope: !156)
!189 = !DILocation(line: 127, column: 5, scope: !156)
!190 = !DILocation(line: 128, column: 5, scope: !156)
!191 = distinct !DISubprogram(name: "report", scope: !3, file: !3, line: 170, type: !192, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!192 = !DISubroutineType(types: !193)
!193 = !{null, !194, !6, !6}
!194 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !195, size: 64)
!195 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!196 = !DILocalVariable(name: "entries", arg: 1, scope: !191, file: !3, line: 170, type: !194)
!197 = !DILocation(line: 0, scope: !191)
!198 = !DILocalVariable(name: "n", arg: 2, scope: !191, file: !3, line: 170, type: !6)
!199 = !DILocalVariable(name: "total", arg: 3, scope: !191, file: !3, line: 170, type: !6)
!200 = !DILocation(line: 171, column: 17, scope: !191)
!201 = !DILocalVariable(name: "shown", scope: !191, file: !3, line: 171, type: !6)
!202 = !DILocation(line: 172, column: 5, scope: !191)
!203 = !DILocalVariable(name: "i", scope: !204, file: !3, line: 173, type: !6)
!204 = distinct !DILexicalBlock(scope: !191, file: !3, line: 173, column: 5)
!205 = !DILocation(line: 0, scope: !204)
!206 = !DILocation(line: 173, column: 10, scope: !204)
!207 = !DILocation(line: 173, scope: !204)
!208 = !DILocation(line: 173, column: 23, scope: !209)
!209 = distinct !DILexicalBlock(scope: !204, file: !3, line: 173, column: 5)
!210 = !DILocation(line: 173, column: 5, scope: !204)
!211 = !DILocation(line: 174, column: 30, scope: !212)
!212 = distinct !DILexicalBlock(scope: !209, file: !3, line: 173, column: 37)
!213 = !DILocation(line: 174, column: 58, scope: !212)
!214 = !DILocation(line: 174, column: 9, scope: !212)
!215 = !DILocation(line: 175, column: 30, scope: !212)
!216 = !DILocation(line: 175, column: 48, scope: !212)
!217 = !DILocation(line: 175, column: 9, scope: !212)
!218 = !DILocation(line: 173, column: 33, scope: !209)
!219 = !DILocation(line: 173, column: 5, scope: !209)
!220 = distinct !{!220, !210, !221, !154}
!221 = !DILocation(line: 176, column: 5, scope: !204)
!222 = !DILocation(line: 177, column: 32, scope: !191)
!223 = !DILocalVariable(name: "word", scope: !191, file: !3, line: 177, type: !194)
!224 = !DILocation(line: 178, column: 14, scope: !225)
!225 = distinct !DILexicalBlock(scope: !191, file: !3, line: 178, column: 9)
!226 = !DILocation(line: 179, column: 9, scope: !227)
!227 = distinct !DILexicalBlock(scope: !225, file: !3, line: 178, column: 23)
!228 = !DILocation(line: 180, column: 5, scope: !227)
!229 = !DILocation(line: 181, column: 43, scope: !191)
!230 = !DILocation(line: 181, column: 5, scope: !191)
!231 = !DILocation(line: 182, column: 37, scope: !191)
!232 = !DILocation(line: 182, column: 5, scope: !191)
!233 = !DILocation(line: 183, column: 1, scope: !191)
!234 = distinct !DISubprogram(name: "table_lookup", scope: !3, file: !3, line: 64, type: !235, scopeLine: 64, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!235 = !DISubroutineType(types: !236)
!236 = !{!6, !159, !74}
!237 = !DILocalVariable(name: "table", arg: 1, scope: !234, file: !3, line: 64, type: !159)
!238 = !DILocation(line: 0, scope: !234)
!239 = !DILocalVariable(name: "word", arg: 2, scope: !234, file: !3, line: 64, type: !74)
!240 = !DILocation(line: 65, column: 26, scope: !234)
!241 = !DILocalVariable(name: "index", scope: !234, file: !3, line: 65, type: !12)
!242 = !DILocalVariable(name: "probe", scope: !243, file: !3, line: 66, type: !6)
!243 = distinct !DILexicalBlock(scope: !234, file: !3, line: 66, column: 5)
!244 = !DILocation(line: 0, scope: !243)
!245 = !DILocation(line: 66, column: 10, scope: !243)
!246 = !DILocation(line: 66, scope: !243)
!247 = !DILocation(line: 66, column: 31, scope: !248)
!248 = distinct !DILexicalBlock(scope: !243, file: !3, line: 66, column: 5)
!249 = !DILocation(line: 66, column: 5, scope: !243)
!250 = !DILocation(line: 67, column: 37, scope: !251)
!251 = distinct !DILexicalBlock(scope: !248, file: !3, line: 66, column: 54)
!252 = !DILocalVariable(name: "slot", scope: !251, file: !3, line: 67, type: !194)
!253 = !DILocation(line: 0, scope: !251)
!254 = !DILocation(line: 68, column: 19, scope: !255)
!255 = distinct !DILexicalBlock(scope: !251, file: !3, line: 68, column: 13)
!256 = !DILocation(line: 68, column: 25, scope: !255)
!257 = !DILocation(line: 71, column: 13, scope: !258)
!258 = distinct !DILexicalBlock(scope: !251, file: !3, line: 71, column: 13)
!259 = !DILocation(line: 71, column: 38, scope: !258)
!260 = !DILocation(line: 74, column: 24, scope: !251)
!261 = !DILocation(line: 66, column: 50, scope: !248)
!262 = !DILocation(line: 66, column: 5, scope: !248)
!263 = distinct !{!263, !249, !264, !154}
!264 = !DILocation(line: 75, column: 5, scope: !243)
!265 = !DILocation(line: 77, column: 1, scope: !234)
!266 = distinct !DISubprogram(name: "next_word", scope: !3, file: !3, line: 80, type: !267, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!267 = !DISubroutineType(types: !268)
!268 = !{!6, !269, !270}
!269 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64)
!270 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!271 = !DILocalVariable(name: "text", arg: 1, scope: !266, file: !3, line: 80, type: !269)
!272 = !DILocation(line: 0, scope: !266)
!273 = !DILocalVariable(name: "word", arg: 2, scope: !266, file: !3, line: 80, type: !270)
!274 = !DILocation(line: 81, column: 21, scope: !266)
!275 = !DILocalVariable(name: "p", scope: !266, file: !3, line: 81, type: !74)
!276 = !DILocation(line: 82, column: 5, scope: !266)
!277 = !DILocation(line: 82, column: 12, scope: !266)
!278 = !DILocation(line: 82, column: 15, scope: !266)
!279 = !DILocation(line: 82, column: 23, scope: !266)
!280 = !DILocation(line: 82, column: 27, scope: !266)
!281 = !DILocation(line: 82, column: 26, scope: !266)
!282 = !DILocation(line: 83, column: 10, scope: !283)
!283 = distinct !DILexicalBlock(scope: !266, file: !3, line: 82, column: 55)
!284 = distinct !{!284, !276, !285, !154}
!285 = !DILocation(line: 84, column: 5, scope: !266)
!286 = !DILocalVariable(name: "length", scope: !266, file: !3, line: 85, type: !6)
!287 = !DILocation(line: 86, column: 5, scope: !266)
!288 = !DILocation(line: 86, column: 35, scope: !266)
!289 = !DILocation(line: 86, column: 12, scope: !266)
!290 = !DILocation(line: 87, column: 20, scope: !291)
!291 = distinct !DILexicalBlock(scope: !292, file: !3, line: 87, column: 13)
!292 = distinct !DILexicalBlock(scope: !266, file: !3, line: 86, column: 40)
!293 = !DILocation(line: 88, column: 44, scope: !294)
!294 = distinct !DILexicalBlock(scope: !291, file: !3, line: 87, column: 36)
!295 = !DILocation(line: 88, column: 36, scope: !294)
!296 = !DILocation(line: 88, column: 30, scope: !294)
!297 = !DILocation(line: 88, column: 24, scope: !294)
!298 = !DILocation(line: 88, column: 13, scope: !294)
!299 = !DILocation(line: 88, column: 28, scope: !294)
!300 = !DILocation(line: 89, column: 9, scope: !294)
!301 = !DILocation(line: 90, column: 10, scope: !292)
!302 = distinct !{!302, !287, !303, !154}
!303 = !DILocation(line: 91, column: 5, scope: !266)
!304 = !DILocation(line: 92, column: 5, scope: !266)
!305 = !DILocation(line: 92, column: 18, scope: !266)
!306 = !DILocation(line: 93, column: 11, scope: !266)
!307 = !DILocation(line: 94, column: 5, scope: !266)
!308 = distinct !DISubprogram(name: "table_add", scope: !3, file: !3, line: 44, type: !309, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!309 = !DISubroutineType(types: !310)
!310 = !{!6, !126, !74, !6}
!311 = !DILocalVariable(name: "table", arg: 1, scope: !308, file: !3, line: 44, type: !126)
!312 = !DILocation(line: 0, scope: !308)
!313 = !DILocalVariable(name: "word", arg: 2, scope: !308, file: !3, line: 44, type: !74)
!314 = !DILocalVariable(name: "position", arg: 3, scope: !308, file: !3, line: 44, type: !6)
!315 = !DILocation(line: 45, column: 26, scope: !308)
!316 = !DILocalVariable(name: "index", scope: !308, file: !3, line: 45, type: !12)
!317 = !DILocalVariable(name: "probe", scope: !318, file: !3, line: 46, type: !6)
!318 = distinct !DILexicalBlock(scope: !308, file: !3, line: 46, column: 5)
!319 = !DILocation(line: 0, scope: !318)
!320 = !DILocation(line: 46, column: 10, scope: !318)
!321 = !DILocation(line: 46, scope: !318)
!322 = !DILocation(line: 46, column: 31, scope: !323)
!323 = distinct !DILexicalBlock(scope: !318, file: !3, line: 46, column: 5)
!324 = !DILocation(line: 46, column: 5, scope: !318)
!325 = !DILocation(line: 47, column: 31, scope: !326)
!326 = distinct !DILexicalBlock(scope: !323, file: !3, line: 46, column: 54)
!327 = !DILocalVariable(name: "slot", scope: !326, file: !3, line: 47, type: !161)
!328 = !DILocation(line: 0, scope: !326)
!329 = !DILocation(line: 48, column: 19, scope: !330)
!330 = distinct !DILexicalBlock(scope: !326, file: !3, line: 48, column: 13)
!331 = !DILocation(line: 48, column: 25, scope: !330)
!332 = !DILocation(line: 49, column: 13, scope: !333)
!333 = distinct !DILexicalBlock(scope: !330, file: !3, line: 48, column: 31)
!334 = !DILocation(line: 50, column: 25, scope: !333)
!335 = !DILocation(line: 51, column: 19, scope: !333)
!336 = !DILocation(line: 51, column: 30, scope: !333)
!337 = !DILocation(line: 52, column: 20, scope: !333)
!338 = !DILocation(line: 52, column: 24, scope: !333)
!339 = !DILocation(line: 53, column: 13, scope: !333)
!340 = !DILocation(line: 55, column: 13, scope: !341)
!341 = distinct !DILexicalBlock(scope: !326, file: !3, line: 55, column: 13)
!342 = !DILocation(line: 55, column: 38, scope: !341)
!343 = !DILocation(line: 56, column: 24, scope: !344)
!344 = distinct !DILexicalBlock(scope: !341, file: !3, line: 55, column: 44)
!345 = !DILocation(line: 57, column: 13, scope: !344)
!346 = !DILocation(line: 59, column: 24, scope: !326)
!347 = !DILocation(line: 46, column: 50, scope: !323)
!348 = !DILocation(line: 46, column: 5, scope: !323)
!349 = distinct !{!349, !324, !350, !154}
!350 = !DILocation(line: 60, column: 5, scope: !318)
!351 = !DILocation(line: 62, column: 1, scope: !308)
!352 = distinct !DISubprogram(name: "hash_word", scope: !3, file: !3, line: 30, type: !353, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!353 = !DISubroutineType(types: !354)
!354 = !{!12, !74}
!355 = !DILocalVariable(name: "word", arg: 1, scope: !352, file: !3, line: 30, type: !74)
!356 = !DILocation(line: 0, scope: !352)
!357 = !DILocalVariable(name: "hash", scope: !352, file: !3, line: 31, type: !12)
!358 = !DILocalVariable(name: "p", scope: !359, file: !3, line: 32, type: !74)
!359 = distinct !DILexicalBlock(scope: !352, file: !3, line: 32, column: 5)
!360 = !DILocation(line: 0, scope: !359)
!361 = !DILocation(line: 32, column: 10, scope: !359)
!362 = !DILocation(line: 32, scope: !359)
!363 = !DILocation(line: 32, column: 32, scope: !364)
!364 = distinct !DILexicalBlock(scope: !359, file: !3, line: 32, column: 5)
!365 = !DILocation(line: 32, column: 35, scope: !364)
!366 = !DILocation(line: 32, column: 5, scope: !359)
!367 = !DILocation(line: 33, column: 17, scope: !368)
!368 = distinct !DILexicalBlock(scope: !364, file: !3, line: 32, column: 49)
!369 = !DILocation(line: 33, column: 14, scope: !368)
!370 = !DILocation(line: 34, column: 14, scope: !368)
!371 = !DILocation(line: 32, column: 45, scope: !364)
!372 = !DILocation(line: 32, column: 5, scope: !364)
!373 = distinct !{!373, !366, !374, !154}
!374 = !DILocation(line: 35, column: 5, scope: !359)
!375 = !DILocation(line: 36, column: 5, scope: !352)
!376 = distinct !DISubprogram(name: "by_count", scope: !3, file: !3, line: 111, type: !377, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!377 = !DISubroutineType(types: !378)
!378 = !{!6, !379, !379}
!379 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !380, size: 64)
!380 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!381 = !DILocalVariable(name: "a", arg: 1, scope: !376, file: !3, line: 111, type: !379)
!382 = !DILocation(line: 0, scope: !376)
!383 = !DILocalVariable(name: "b", arg: 2, scope: !376, file: !3, line: 111, type: !379)
!384 = !DILocalVariable(name: "x", scope: !376, file: !3, line: 112, type: !194)
!385 = !DILocalVariable(name: "y", scope: !376, file: !3, line: 113, type: !194)
!386 = !DILocation(line: 114, column: 12, scope: !387)
!387 = distinct !DILexicalBlock(scope: !376, file: !3, line: 114, column: 9)
!388 = !DILocation(line: 114, column: 24, scope: !387)
!389 = !DILocation(line: 114, column: 18, scope: !387)
!390 = !DILocation(line: 115, column: 25, scope: !391)
!391 = distinct !DILexicalBlock(scope: !387, file: !3, line: 114, column: 31)
!392 = !DILocation(line: 115, column: 9, scope: !391)
!393 = !DILocation(line: 117, column: 15, scope: !376)
!394 = !DILocation(line: 117, column: 31, scope: !376)
!395 = !DILocation(line: 117, column: 26, scope: !376)
!396 = !DILocation(line: 117, column: 5, scope: !376)
!397 = !DILocation(line: 118, column: 1, scope: !376)
!398 = distinct !DISubprogram(name: "print_bar", scope: !3, file: !3, line: 162, type: !399, scopeLine: 162, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!399 = !DISubroutineType(types: !400)
!400 = !{null, !6, !6}
!401 = !DILocalVariable(name: "count", arg: 1, scope: !398, file: !3, line: 162, type: !6)
!402 = !DILocation(line: 0, scope: !398)
!403 = !DILocalVariable(name: "widest", arg: 2, scope: !398, file: !3, line: 162, type: !6)
!404 = !DILocation(line: 163, column: 24, scope: !398)
!405 = !DILocation(line: 163, column: 17, scope: !398)
!406 = !DILocation(line: 163, column: 36, scope: !398)
!407 = !DILocation(line: 163, column: 41, scope: !398)
!408 = !DILocalVariable(name: "width", scope: !398, file: !3, line: 163, type: !6)
!409 = !DILocalVariable(name: "i", scope: !410, file: !3, line: 164, type: !6)
!410 = distinct !DILexicalBlock(scope: !398, file: !3, line: 164, column: 5)
!411 = !DILocation(line: 0, scope: !410)
!412 = !DILocation(line: 164, column: 10, scope: !410)
!413 = !DILocation(line: 164, scope: !410)
!414 = !DILocation(line: 164, column: 23, scope: !415)
!415 = distinct !DILexicalBlock(scope: !410, file: !3, line: 164, column: 5)
!416 = !DILocation(line: 164, column: 5, scope: !410)
!417 = !DILocation(line: 165, column: 9, scope: !418)
!418 = distinct !DILexicalBlock(scope: !415, file: !3, line: 164, column: 37)
!419 = !DILocation(line: 164, column: 33, scope: !415)
!420 = !DILocation(line: 164, column: 5, scope: !415)
!421 = distinct !{!421, !416, !422, !154}
!422 = !DILocation(line: 166, column: 5, scope: !410)
!423 = !DILocation(line: 167, column: 5, scope: !398)
!424 = !DILocation(line: 168, column: 1, scope: !398)
!425 = distinct !DISubprogram(name: "longest", scope: !3, file: !3, line: 141, type: !426, scopeLine: 141, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!426 = !DISubroutineType(types: !427)
!427 = !{!194, !194, !6}
!428 = !DILocalVariable(name: "entries", arg: 1, scope: !425, file: !3, line: 141, type: !194)
!429 = !DILocation(line: 0, scope: !425)
!430 = !DILocalVariable(name: "n", arg: 2, scope: !425, file: !3, line: 141, type: !6)
!431 = !DILocalVariable(name: "best", scope: !425, file: !3, line: 142, type: !194)
!432 = !DILocalVariable(name: "best_length", scope: !425, file: !3, line: 143, type: !30)
!433 = !DILocalVariable(name: "i", scope: !434, file: !3, line: 144, type: !6)
!434 = distinct !DILexicalBlock(scope: !425, file: !3, line: 144, column: 5)
!435 = !DILocation(line: 0, scope: !434)
!436 = !DILocation(line: 144, column: 10, scope: !434)
!437 = !DILocation(line: 144, scope: !434)
!438 = !DILocation(line: 144, column: 23, scope: !439)
!439 = distinct !DILexicalBlock(scope: !434, file: !3, line: 144, column: 5)
!440 = !DILocation(line: 144, column: 5, scope: !434)
!441 = !DILocation(line: 145, column: 32, scope: !442)
!442 = distinct !DILexicalBlock(scope: !439, file: !3, line: 144, column: 33)
!443 = !DILocation(line: 145, column: 25, scope: !442)
!444 = !DILocalVariable(name: "length", scope: !442, file: !3, line: 145, type: !30)
!445 = !DILocation(line: 0, scope: !442)
!446 = !DILocation(line: 146, column: 20, scope: !447)
!447 = distinct !DILexicalBlock(scope: !442, file: !3, line: 146, column: 13)
!448 = !DILocation(line: 144, column: 29, scope: !439)
!449 = !DILocation(line: 144, column: 5, scope: !439)
!450 = distinct !{!450, !440, !451, !154}
!451 = !DILocation(line: 150, column: 5, scope: !434)
!452 = !DILocation(line: 151, column: 5, scope: !425)
!453 = distinct !DISubprogram(name: "mean_length", scope: !3, file: !3, line: 131, type: !454, scopeLine: 131, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!454 = !DISubroutineType(types: !455)
!455 = !{!35, !194, !6}
!456 = !DILocalVariable(name: "entries", arg: 1, scope: !453, file: !3, line: 131, type: !194)
!457 = !DILocation(line: 0, scope: !453)
!458 = !DILocalVariable(name: "n", arg: 2, scope: !453, file: !3, line: 131, type: !6)
!459 = !DILocalVariable(name: "letters", scope: !453, file: !3, line: 132, type: !34)
!460 = !DILocalVariable(name: "words", scope: !453, file: !3, line: 133, type: !34)
!461 = !DILocalVariable(name: "i", scope: !462, file: !3, line: 134, type: !6)
!462 = distinct !DILexicalBlock(scope: !453, file: !3, line: 134, column: 5)
!463 = !DILocation(line: 0, scope: !462)
!464 = !DILocation(line: 134, column: 10, scope: !462)
!465 = !DILocation(line: 134, scope: !462)
!466 = !DILocation(line: 134, column: 23, scope: !467)
!467 = distinct !DILexicalBlock(scope: !462, file: !3, line: 134, column: 5)
!468 = !DILocation(line: 134, column: 5, scope: !462)
!469 = !DILocation(line: 136, column: 18, scope: !470)
!470 = distinct !DILexicalBlock(scope: !467, file: !3, line: 134, column: 33)
!471 = !DILocation(line: 136, column: 29, scope: !470)
!472 = !DILocation(line: 136, column: 15, scope: !470)
!473 = !DILocation(line: 135, column: 26, scope: !470)
!474 = !DILocation(line: 135, column: 50, scope: !470)
!475 = !DILocation(line: 135, column: 17, scope: !470)
!476 = !DILocation(line: 134, column: 29, scope: !467)
!477 = !DILocation(line: 134, column: 5, scope: !467)
!478 = distinct !{!478, !468, !479, !154}
!479 = !DILocation(line: 137, column: 5, scope: !462)
!480 = !DILocation(line: 138, column: 18, scope: !453)
!481 = !DILocation(line: 138, column: 12, scope: !453)
!482 = !DILocation(line: 138, column: 5, scope: !453)
!483 = distinct !DISubprogram(name: "singletons", scope: !3, file: !3, line: 154, type: !484, scopeLine: 154, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!484 = !DISubroutineType(types: !485)
!485 = !{!6, !194, !6}
!486 = !DILocalVariable(name: "entries", arg: 1, scope: !483, file: !3, line: 154, type: !194)
!487 = !DILocation(line: 0, scope: !483)
!488 = !DILocalVariable(name: "n", arg: 2, scope: !483, file: !3, line: 154, type: !6)
!489 = !DILocalVariable(name: "count", scope: !483, file: !3, line: 155, type: !6)
!490 = !DILocalVariable(name: "i", scope: !491, file: !3, line: 156, type: !6)
!491 = distinct !DILexicalBlock(scope: !483, file: !3, line: 156, column: 5)
!492 = !DILocation(line: 0, scope: !491)
!493 = !DILocation(line: 156, column: 10, scope: !491)
!494 = !DILocation(line: 156, scope: !491)
!495 = !DILocation(line: 156, column: 27, scope: !496)
!496 = distinct !DILexicalBlock(scope: !491, file: !3, line: 156, column: 5)
!497 = !DILocation(line: 156, column: 32, scope: !496)
!498 = !DILocation(line: 156, column: 35, scope: !496)
!499 = !DILocation(line: 156, column: 46, scope: !496)
!500 = !DILocation(line: 156, column: 52, scope: !496)
!501 = !DILocation(line: 156, column: 5, scope: !491)
!502 = !DILocation(line: 157, column: 14, scope: !503)
!503 = distinct !DILexicalBlock(scope: !496, file: !3, line: 156, column: 63)
!504 = !DILocation(line: 156, column: 5, scope: !496)
!505 = distinct !{!505, !501, !506, !154}
!506 = !DILocation(line: 158, column: 5, scope: !491)
!507 = !DILocation(line: 159, column: 5, scope: !483)
