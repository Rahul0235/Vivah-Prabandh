package com.vivahprabandh.repository;

import com.vivahprabandh.entity.Expense;
import com.vivahprabandh.dto.CategoryExpenseDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface ExpenseRepository extends JpaRepository<Expense, Long> {

    // 🔹 Basic Queries
    List<Expense> findByEventId(Long eventId);

    List<Expense> findByEventIdAndCategoryIgnoreCase(Long eventId, String category);

    List<Expense> findByEventIdAndDateBetween(Long eventId, LocalDate startDate, LocalDate endDate);

    List<Expense> findByEventIdAndCategoryIgnoreCaseAndDateBetween(
            Long eventId, String category, LocalDate startDate, LocalDate endDate);

    // 🔹 Analytics — Category Wise (Pie Chart)
    @Query("SELECT new com.vivahprabandh.dto.CategoryExpenseDTO(e.category, SUM(e.amount)) " +
           "FROM Expense e WHERE e.event.id = :eventId GROUP BY e.category")
    List<CategoryExpenseDTO> getCategoryWiseExpenses(@Param("eventId") Long eventId);

   // 🔹 Analytics — Monthly (Bar Chart) FINAL FIX
@Query(value = "SELECT DATE_FORMAT(date, '%Y-%m') AS month, SUM(amount) AS totalAmount " +
       "FROM expenses WHERE event_id = :eventId " +
       "GROUP BY DATE_FORMAT(date, '%Y-%m') " +
       "ORDER BY DATE_FORMAT(date, '%Y-%m')",
       nativeQuery = true)
List<Object[]> getMonthlyExpensesRaw(@Param("eventId") Long eventId);
}